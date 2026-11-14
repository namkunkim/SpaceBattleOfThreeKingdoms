"""Single-PC, two-live-engine owner fencing over a pinned real-parent committed C0.
The explicit owner transfer and artifact registry belong to a trusted test coordinator.
No product principal, lease expiry policy, public entry, or existing user save is used.
"""
import argparse
import base64
from contextlib import closing
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import sys
import time

import cross_counter_evaluation_durable as durable

SOURCE_DB_SHA = 'da860ed2199bbf1efbc75407b27b29174a46ab9a394d9e5536cd7ecef24143cd'
C0_SHA = 'a47a50dc850413f9b520de92c3935523fe88006dfbde4a247ff1d2ad9149bf53'
OPERATION = 'cross-counter-drill-successor-eval-v1/04e09dc8fef4a28dca35aeabe6a4cb73b766111f59c8c78a74262a5611d5dd9e'
FENCE_KEYS = {'operation_id', 'owner_id', 'epoch', 'checkpoint_sha'}
INTENT_KEYS = {'request_id', 'base_sha', 'proposal_id', 'candidate_sha'}
SHA_PATTERN = '[0-9a-f]{64}'


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def sha(value):
    return hashlib.sha256(value).hexdigest()


def source_record(path):
    if durable.file_sha(path) != SOURCE_DB_SHA:
        raise ValueError('source database pin mismatch')
    with closing(sqlite3.connect(Path(path).resolve().as_uri() + '?mode=ro', uri=True)) as db:
        rows = db.execute('SELECT response,c0_blob,c0_sha,binding FROM transitions').fetchall()
        assert db.execute('PRAGMA integrity_check').fetchone() == ('ok',)
    assert len(rows) == 1
    response, blob, packet_sha, binding = rows[0]
    binding, response = json.loads(binding), json.loads(response)
    assert packet_sha == sha(blob) == binding['packet_sha256'] == C0_SHA
    assert binding['operation_id'] == response['operation_id'] == OPERATION
    return {'operation_id': OPERATION, 'packet_b64': base64.b64encode(blob).decode(), 'binding': binding}


def initialize(path, record, owner):
    with closing(durable.connect(path)) as db:
        db.executescript('''
            CREATE TABLE head(operation TEXT PRIMARY KEY, owner TEXT NOT NULL, epoch INTEGER NOT NULL,
                revision INTEGER NOT NULL, checkpoint_sha TEXT NOT NULL, blob BLOB NOT NULL, binding TEXT NOT NULL);
            CREATE TABLE proposals(id TEXT PRIMARY KEY, owner TEXT NOT NULL, epoch INTEGER NOT NULL,
                base_sha TEXT NOT NULL, candidate_sha TEXT NOT NULL, artifact_sha TEXT NOT NULL,
                blob BLOB NOT NULL, binding TEXT NOT NULL, engine_pid INTEGER NOT NULL);
            CREATE TABLE receipts(request_id TEXT PRIMARY KEY, intent_digest TEXT NOT NULL, response TEXT NOT NULL);
            CREATE TABLE checkpoints(revision INTEGER PRIMARY KEY, checkpoint_sha TEXT NOT NULL UNIQUE,
                blob BLOB NOT NULL, binding TEXT NOT NULL);
            CREATE TABLE transfers(epoch INTEGER PRIMARY KEY, old_owner TEXT NOT NULL, new_owner TEXT NOT NULL,
                checkpoint_sha TEXT NOT NULL);
        ''')
        blob = base64.b64decode(record['packet_b64'], validate=True)
        bind = json.dumps(record['binding'])
        db.execute('BEGIN IMMEDIATE')
        db.execute('INSERT INTO head VALUES(?,?,1,0,?,?,?)', (OPERATION, owner, C0_SHA, blob, bind))
        db.execute('INSERT INTO checkpoints VALUES(0,?,?,?)', (C0_SHA, blob, bind))
        db.execute('COMMIT')


def authorize(db, fence):
    if (type(fence) is not dict or set(fence) != FENCE_KEYS
            or any(type(fence[k]) is not str for k in FENCE_KEYS - {'epoch'})
            or type(fence['epoch']) is not int or fence['epoch'] < 1
            or not re.fullmatch(SHA_PATTERN, fence['checkpoint_sha'])):
        return None, {'error': 'invalid_fence'}
    row = db.execute('SELECT owner,epoch,revision,checkpoint_sha,blob,binding FROM head WHERE operation=?',
                     (fence['operation_id'],)).fetchone()
    if row is None:
        return None, {'error': 'unknown_operation'}
    if (fence['owner_id'], fence['epoch']) != row[:2]:
        return None, {'error': 'stale_owner'}
    if fence['checkpoint_sha'] != row[3]:
        return None, {'error': 'stale_checkpoint'}
    return row, None


def fenced(path, fence, mode, intent=None):
    # No Godot call, file artifact read, or external wait inside this writer transaction.
    with closing(durable.connect(path)) as db:
        db.execute('BEGIN IMMEDIATE')
        row, error = authorize(db, fence)
        if error:
            return error
        owner, epoch, revision, current_sha, blob, binding = row
        if mode == 'read':
            if sha(blob) != current_sha or json.loads(binding)['packet_sha256'] != current_sha:
                return {'error': 'corrupt_head'}
            return {'operation_id': fence['operation_id'], 'revision': revision,
                    'packet_b64': base64.b64encode(blob).decode(), 'binding': json.loads(binding)}
        if (type(intent) is not dict or set(intent) != INTENT_KEYS
                or any(type(v) is not str for v in intent.values())
                or not re.fullmatch('[a-z0-9-]{1,64}', intent['request_id'])
                or not re.fullmatch('[a-z0-9-]{1,64}', intent['proposal_id'])
                or any(not re.fullmatch(SHA_PATTERN, intent[k]) for k in ('base_sha', 'candidate_sha'))):
            return {'error': 'invalid_intent'}
        # The *current* owner/epoch/head check precedes historical idempotency.
        existing = db.execute('SELECT intent_digest,response FROM receipts WHERE request_id=?',
                              (intent['request_id'],)).fetchone()
        if existing:
            return json.loads(existing[1]) if existing[0] == durable.digest(intent) else {'error': 'intent_conflict'}
        if mode == 'receipt':
            return {'error': 'receipt_missing'}
        if mode != 'commit':
            return {'error': 'invalid_mode'}
        if intent['base_sha'] != current_sha:
            return {'error': 'stale_base'}
        proposal = db.execute('SELECT owner,epoch,base_sha,candidate_sha,blob,binding FROM proposals WHERE id=?',
                              (intent['proposal_id'],)).fetchone()
        if proposal is None:
            return {'error': 'unregistered_proposal'}
        if proposal[:4] != (owner, epoch, current_sha, intent['candidate_sha']):
            return {'error': 'proposal_fence_mismatch'}
        candidate_blob, candidate_bind = proposal[4:]
        decoded_bind = json.loads(candidate_bind)
        if (sha(candidate_blob) != intent['candidate_sha']
                or decoded_bind['packet_sha256'] != intent['candidate_sha']
                or decoded_bind['operation_id'] != fence['operation_id']):
            return {'error': 'proposal_blob_mismatch'}
        response = {'operation_id': fence['operation_id'], 'owner_id': owner, 'epoch': epoch,
                    'revision': revision + 1, 'checkpoint_sha': intent['candidate_sha'], 'request_id': intent['request_id']}
        changed = db.execute('UPDATE head SET revision=?,checkpoint_sha=?,blob=?,binding=? '
                             'WHERE operation=? AND owner=? AND epoch=? AND checkpoint_sha=? AND revision=?',
                             (revision + 1, intent['candidate_sha'], candidate_blob, candidate_bind,
                              fence['operation_id'], owner, epoch, current_sha, revision))
        assert changed.rowcount == 1
        db.execute('INSERT INTO checkpoints VALUES(?,?,?,?)',
                   (revision + 1, intent['candidate_sha'], candidate_blob, candidate_bind))
        db.execute('INSERT INTO receipts VALUES(?,?,?)',
                   (intent['request_id'], durable.digest(intent), json.dumps(response)))
        db.execute('COMMIT')
        return response


def register_proposal(path, fence, proposal_id, artifact, expected_pid):
    # Private coordinator API: the exact response came from the isolated engine process.
    # Workers have no registration CLI and cannot assert their own validation flag.
    value = read(artifact)
    assert value['ok'] is True and value['published'] is False and value['pid'] == expected_pid
    blob, bind = base64.b64decode(value['packet_b64'], validate=True), value['binding']
    assert value['base_sha'] == fence['checkpoint_sha'] and value['operation_id'] == OPERATION
    assert sha(blob) == bind['packet_sha256'] == value['observation']['packet_sha256']
    assert bind['operation_id'] == OPERATION
    with closing(durable.connect(path)) as db:
        db.execute('BEGIN IMMEDIATE')
        _row, error = authorize(db, fence)
        if error:
            return error
        db.execute('INSERT INTO proposals VALUES(?,?,?,?,?,?,?,?,?)',
                   (proposal_id, fence['owner_id'], fence['epoch'], value['base_sha'], sha(blob),
                    durable.file_sha(artifact), blob, json.dumps(bind), expected_pid))
        db.execute('COMMIT')
    return {'request_id': proposal_id, 'base_sha': value['base_sha'],
            'proposal_id': proposal_id, 'candidate_sha': sha(blob)}


def transfer(path, fence, new_owner):
    # Explicit fixture-administrator handoff only; no lease duration or expiry policy.
    assert type(new_owner) is str and new_owner and new_owner != fence['owner_id']
    with closing(durable.connect(path)) as db:
        db.execute('BEGIN IMMEDIATE')
        row, error = authorize(db, fence)
        if error:
            return error
        changed = db.execute('UPDATE head SET owner=?,epoch=epoch+1 '
                             'WHERE operation=? AND owner=? AND epoch=? AND checkpoint_sha=?',
                             (new_owner, fence['operation_id'], row[0], row[1], row[3]))
        assert changed.rowcount == 1
        db.execute('INSERT INTO transfers VALUES(?,?,?,?)', (row[1] + 1, row[0], new_owner, row[3]))
        db.execute('COMMIT')
    return dict(fence, owner_id=new_owner, epoch=row[1] + 1)


class Engine:
    def __init__(self, run, label):
        self.run, self.label, self.seq = run, label, 0
        self.directory = run.root / label
        (self.directory / 'profile' / 'Roaming').mkdir(parents=True)
        (self.directory / 'profile' / 'Local').mkdir()
        env = dict(os.environ, APPDATA=str(self.directory / 'profile' / 'Roaming'),
                   LOCALAPPDATA=str(self.directory / 'profile' / 'Local'),
                   SBTK_CROSS_COUNTER_ISOLATED_ROOT=str(self.directory / 'profile'),
                   SBTK_CROSS_COUNTER_RESULT_DIR=str(self.directory), SBTK_CROSS_COUNTER_OPERATION_ID=OPERATION)
        self.command = [str(run.args.engine), '--headless', '--max-fps', '60', '--path', str(run.args.worktree),
                        '--script', 'res://tests/cross_counter_owner_fencing_bridge.gd']
        self.started = time.time()
        self.stdout = (self.directory / 'stdout.log').open('wb')
        self.stderr = (self.directory / 'stderr.log').open('wb')
        self.process = subprocess.Popen(self.command, env=env, stdout=self.stdout, stderr=self.stderr,
                                        creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        run.engines.append(self)
        self.ready = self.wait('ready.json')
        self.pid, self.owner = self.ready['pid'], label + '-' + str(self.ready['pid'])
        run.check(label + ': fresh profile and no initial live owner', self.ready['live'] is False
                  and Path(self.ready['user_data_dir']).is_relative_to(self.directory / 'profile'))

    def wait(self, name):
        deadline = time.monotonic() + 90
        path = self.directory / name
        while True:
            try:
                return read(path)
            except (FileNotFoundError, PermissionError):
                # Windows may briefly deny opening the just-renamed IPC file.
                # Retry only availability/sharing failures, never malformed JSON.
                if (self.process.poll() is not None and not path.exists()) or time.monotonic() > deadline:
                    raise RuntimeError(self.label + ': unavailable ' + name)
                time.sleep(.02)

    def call(self, action, **kwargs):
        self.seq += 1
        temporary = self.directory / ('request-%03d.tmp' % self.seq)
        durable.write(temporary, dict(kwargs, action=action))
        temporary.replace(self.directory / ('request-%03d.json' % self.seq))
        path = self.directory / ('response-%03d.json' % self.seq)
        response = self.wait(path.name)
        assert response['pid'] == self.pid and response['sequence'] == self.seq
        return path, response

    def install(self, record):
        _, result = self.call('install', fixture_authority_validated=True, record=record)
        self.run.check(self.label + ': restore and install exact authorized checkpoint',
                       result['ok'] and result['observation']['packet_sha256'] == record['binding']['packet_sha256'])
        return result['observation']

    def stage(self, db, fence, name, plan):
        path, result = self.call('stage', base_sha=fence['checkpoint_sha'], plan=plan)
        self.run.check(name + ': private proposal preserves published live head', result['ok']
                       and result['old_observation']['packet_sha256'] == fence['checkpoint_sha'])
        intent = register_proposal(db, fence, name, path, self.pid)
        assert 'error' not in intent
        return intent, result

    def finish(self):
        if self.process.poll() is None:
            self.call('shutdown')
        code = self.process.wait(timeout=30)
        self.stdout.close()
        self.stderr.close()
        durable.write(self.directory / 'run.json', {'command': self.command, 'console_pid': self.process.pid,
                      'engine_pid': self.pid, 'started_unix': self.started, 'finished_unix': time.time(), 'exit_code': code})
        self.run.check(self.label + ': normal exit and empty stderr', code == 0 and (self.directory / 'stderr.log').stat().st_size == 0)
        result = read(self.directory / 'result.json')
        self.run.check(self.label + ': native replay and installation checks passed', result['status'] == 'PASS')
        return {'name': self.label, 'pid': self.pid, 'checks': result['checks_total']}


class Run:
    def __init__(self, args):
        self.args, self.root, self.checks, self.engines, self.workers = args, args.output.resolve(), [], [], []
        self.root.mkdir(parents=True, exist_ok=False)

    def check(self, name, value):
        self.checks.append({'name': name, 'pass': bool(value)})
        print('CROSS_COUNTER_OWNER_FENCE_CHECK', bool(value), name, flush=True)
        if not value:
            raise AssertionError(name)

    def same_base_race(self, db, fence, intent):
        gate = self.root / 'race.go'
        processes = []
        for index in range(2):
            ready = self.root / ('race-%d.ready' % index)
            item = dict(intent, request_id='b-race-%d' % index)
            command = [sys.executable, '-B', __file__, '--worker', '--db', str(db), '--fence', json.dumps(fence),
                       '--intent', json.dumps(item), '--gate', str(gate), '--ready', str(ready)]
            process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                                        creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
            processes.append((process, ready, item, command))
        deadline = time.monotonic() + 15
        while not all(ready.exists() for _, ready, _, _ in processes):
            assert time.monotonic() < deadline
            time.sleep(.01)
        gate.touch(exist_ok=False)
        replies = []
        for process, _, item, command in processes:
            out, err = process.communicate(timeout=30)
            value = json.loads(out)
            row = {'pid': process.pid, 'command': command, 'exit_code': process.returncode,
                   'stdout': out, 'stderr': err, 'intent': item, 'reply': value['reply']}
            self.workers.append(row)
            self.check('race worker %s: distinct process exits cleanly' % process.pid,
                       process.returncode == 0 and not err and value['pid'] == process.pid)
            replies.append((item, value['reply']))
        durable.write(self.root / 'workers.json', self.workers)
        self.check('same-base workers commit once and reject stale checkpoint once',
                   sum('revision' in reply for _, reply in replies) == 1
                   and sum(reply == {'error': 'stale_checkpoint'} for _, reply in replies) == 1)
        return next((item, reply) for item, reply in replies if 'revision' in reply)

    def execute(self):
        record = source_record(self.args.source_db)
        self.check('actual-parent committed C0 and source SQLite bytes are pinned', record['binding']['packet_sha256'] == C0_SHA)
        durable.write(self.root / 'source-c0.json', record)
        a = Engine(self, 'engine-a')
        db = self.root / 'fenced.sqlite'
        initialize(db, record, a.owner)
        fa = {'operation_id': OPERATION, 'owner_id': a.owner, 'epoch': 1, 'checkpoint_sha': C0_SHA}
        observed = a.install(fenced(db, fa, 'read'))
        self.check('A starts at actual unstarted C0 with zero native commands', observed['packet']['tick'] == 0
                   and observed['packet']['bootstrap_done'] is False and observed['native_witness']['command_log'] == [])
        for key, value in [('epoch', True), ('epoch', 1.0), ('owner_id', 7)]:
            self.check('reject noncanonical fence %s=%r' % (key, value),
                       fenced(db, dict(fa, **{key: value}), 'read') == {'error': 'invalid_fence'})
        self.check('operation binding rejects another operation',
                   fenced(db, dict(fa, operation_id=OPERATION + '-other'), 'read') == {'error': 'unknown_operation'})
        first, first_stage = a.stage(db, fa, 'a-start-pending', 'start_pending')
        s1 = first_stage['observation']
        self.check('S1 has one tick, two bootstrap commands, and one pending stop', s1['packet']['tick'] == 1
                   and s1['packet']['clock_ms'] == 100 and len(s1['packet']['pending']) == 1
                   and s1['packet']['pending'][0]['kind'] == 'stop' and s1['packet']['commands'] == []
                   and len(s1['native_witness']['command_log']) == 2)
        for key, value in [('request_id', 1), ('request_id', True)]:
            self.check('reject non-string request id %r' % value,
                       fenced(db, fa, 'commit', dict(first, **{key: value})) == {'error': 'invalid_intent'})
        first_reply = fenced(db, fa, 'commit', first)
        self.check('A commits validated started checkpoint as revision1', first_reply.get('revision') == 1)
        fa = dict(fa, checkpoint_sha=first['candidate_sha'])
        self.check('same-key retry uses current authority fence and returns exact receipt', fenced(db, fa, 'commit', first) == first_reply)
        a_s1 = a.install(fenced(db, fa, 'read'))
        delayed, delayed_stage = a.stage(db, fa, 'a-delayed-advance', 'advance')
        before_handoff = durable.file_sha(db)
        b = Engine(self, 'engine-b')
        self.check('two actual Godot PIDs overlap and B starts after durable S1 commit',
                   a.pid != b.pid and a.process.poll() is None and b.process.poll() is None
                   and a_s1['packet_sha256'] == s1['packet_sha256'])
        premature = dict(fa, owner_id=b.owner, epoch=2)
        self.check('B cannot read before explicit authority handoff', fenced(db, premature, 'read') == {'error': 'stale_owner'})
        self.check('denied premature read leaves SQLite file byte-identical', durable.file_sha(db) == before_handoff)
        self.check('handoff rejects stale checkpoint atomically',
                   transfer(db, dict(fa, checkpoint_sha=C0_SHA), b.owner) == {'error': 'stale_checkpoint'})
        fb = transfer(db, fa, b.owner)
        self.check('explicit fixture handoff increments epoch only and keeps S1 head',
                   fb == dict(fa, owner_id=b.owner, epoch=2))
        handed = durable.file_sha(db)
        for mode, intent in [('read', None), ('commit', delayed), ('receipt', first), ('commit', first)]:
            self.check('revoked A rejects %s before historical receipt lookup' % mode,
                       fenced(db, fa, mode, intent) == {'error': 'stale_owner'})
        self.check('revoked A cannot re-register a validated proposal', register_proposal(db, fa,
                   'a-stale-register', a.directory / ('response-%03d.json' % a.seq), a.pid) == {'error': 'stale_owner'})
        self.check('all stale A requests leave durable database byte-identical', durable.file_sha(db) == handed)
        _, cancelled = a.call('cancel')
        self.check('cancelled stale candidate preserves old local live packet and native instance',
                   cancelled['observation'] == a_s1)
        b_s1 = b.install(fenced(db, fb, 'read'))
        self.check('new PID restores exact started pending checkpoint and native witness',
                   b_s1['packet_sha256'] == a_s1['packet_sha256']
                   and b_s1['native_witness'] == a_s1['native_witness']
                   and b_s1['packet']['pending'] == a_s1['packet']['pending'])
        next_intent, next_stage = b.stage(db, fb, 'b-advance', 'advance')
        self.check('same replayed pending command produces identical candidate across two PIDs',
                   next_intent['candidate_sha'] == delayed['candidate_sha']
                   and next_stage['observation']['native_witness'] == delayed_stage['observation']['native_witness'])
        winner, accepted = self.same_base_race(db, fb, next_intent)
        stale_b = fb.copy()
        fb = dict(fb, checkpoint_sha=accepted['checkpoint_sha'])
        self.check('stale B checkpoint cannot read current authority', fenced(db, stale_b, 'read') == {'error': 'stale_checkpoint'})
        self.check('stale B checkpoint cannot retrieve even accepted receipt', fenced(db, stale_b, 'receipt', winner) == {'error': 'stale_checkpoint'})
        self.check('current owner refreshed head retries accepted request exactly once', fenced(db, fb, 'commit', winner) == accepted)
        self.check('same request with different payload is rejected',
                   fenced(db, fb, 'commit', dict(winner, candidate_sha=C0_SHA)) == {'error': 'intent_conflict'})
        self.check('new request cannot reuse an old candidate base',
                   fenced(db, fb, 'commit', dict(winner, request_id='b-old-base')) == {'error': 'stale_base'})
        self.check('revoked A with current head is still denied by owner epoch',
                   fenced(db, dict(fa, checkpoint_sha=fb['checkpoint_sha']), 'read') == {'error': 'stale_owner'})
        installed = b.install(fenced(db, fb, 'read'))
        packet, log = installed['packet'], installed['native_witness']['command_log']
        self.check('new owner applies pending stop once at tick2 and preserves history', packet['tick'] == 2
                   and packet['pending'] == [] and len(packet['commands']) == 1
                   and packet['commands'][0]['tick'] == 1 and len(packet['commands'][0]['batch']) == 1
                   and packet['commands'][0]['batch'][0]['kind'] == 'stop' and len(log) == 3)
        third, _ = b.stage(db, fb, 'b-next-empty-tick', 'advance')
        third_reply = fenced(db, fb, 'commit', third)
        self.check('current new owner remains able to commit subsequent checkpoint', third_reply.get('revision') == 3)
        fb = dict(fb, checkpoint_sha=third['candidate_sha'])
        final = b.install(fenced(db, fb, 'read'))
        self.check('next tick does not repeat bootstrap or consumed pending stop', final['packet']['tick'] == 3
                   and final['packet']['pending'] == [] and final['packet']['commands'] == packet['commands']
                   and final['native_witness']['command_log'] == log)
        _, a_final = a.call('observe')
        self.check('stale local process never installs its rejected candidate', a_final['observation'] == a_s1 and not a_final['staged'])
        with closing(durable.connect(db)) as connection:
            self.check('final SQLite integrity and exact effect counts', connection.execute('PRAGMA integrity_check').fetchone() == ('ok',)
                       and connection.execute('SELECT COUNT(*) FROM receipts').fetchone() == (3,)
                       and connection.execute('SELECT COUNT(*) FROM checkpoints').fetchone() == (4,)
                       and connection.execute('SELECT COUNT(*) FROM transfers').fetchone() == (1,))
            rows = connection.execute('SELECT revision,checkpoint_sha,blob,binding FROM checkpoints ORDER BY revision').fetchall()
            self.check('every persisted checkpoint BLOB matches its stored SHA and operation binding',
                       all(sha(blob) == h == json.loads(bind)['packet_sha256'] and json.loads(bind)['operation_id'] == OPERATION
                           for _, h, blob, bind in rows))
        engines = [engine.finish() for engine in self.engines]
        self.check('prior immutable source SQLite remains byte-identical', durable.file_sha(self.args.source_db) == SOURCE_DB_SHA)
        return {'schema': 'cross-counter-owner-fencing-proof/1', 'status': 'PASS', 'checks': self.checks,
                'checks_total': len(self.checks), 'checks_passed': len(self.checks), 'engines': engines,
                'worker_pids': [row['pid'] for row in self.workers], 'source_db_sha256': SOURCE_DB_SHA,
                'database_sha256': durable.file_sha(db), 'operation_id': OPERATION, 'final_fence': fb,
                'checkpoints': [{'revision': row[0], 'sha256': row[1]} for row in rows],
                'single_pc': True, 'real_service_authentication': False, 'lease_expiry_policy': False,
                'public_activation': False, 'existing_user_saves_accessed': False,
                'scope': 'Test-coordinator authority for persisted evaluation checkpoints; cached native computation is not revoked.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--worker', action='store_true')
    for key in ('db', 'fence', 'intent', 'gate', 'ready'):
        parser.add_argument('--' + key)
    for key in ('output', 'engine', 'worktree', 'source-db'):
        parser.add_argument('--' + key, type=Path)
    args = parser.parse_args()
    if args.worker:
        Path(args.ready).touch(exist_ok=False)
        deadline = time.monotonic() + 20
        while not Path(args.gate).exists():
            assert time.monotonic() < deadline
            time.sleep(.01)
        reply = fenced(args.db, json.loads(args.fence), 'commit', json.loads(args.intent))
        print(json.dumps({'pid': os.getpid(), 'reply': reply}))
        return
    for name in ('output', 'engine', 'worktree', 'source_db'):
        if getattr(args, name) is None:
            parser.error('--' + name.replace('_', '-') + ' is required')
    run = Run(args)
    try:
        result = run.execute()
    except Exception as error:
        result = {'schema': 'cross-counter-owner-fencing-proof/1', 'status': 'FAIL', 'error': repr(error), 'checks': run.checks}
        durable.write(run.root / 'result.json', result)
        for engine in run.engines:
            if engine.process.poll() is None:
                try:
                    engine.call('shutdown')
                    engine.process.wait(timeout=15)
                except Exception:
                    engine.process.terminate()
        raise
    durable.write(run.root / 'result.json', result)
    print('CROSS_COUNTER_OWNER_FENCING PASS', result['checks_total'], flush=True)


if __name__ == '__main__':
    main()
