"""Bind an engine-validated Cross Counter C0 to single-PC SQLite CAS and restart.
Synthetic isolated parent and fixture actor only. No user saves, public route or real auth.
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

ACTOR = 'cross-counter-local-test-owner'
CAMPAIGN = 'cross-counter-local-test'
DEFINITION = 'cross-counter-drill-successor-eval-v1'
PARENT = {'id': 'red-cliffs-first-operation-dev-v1/synthetic-objective-parent/settlement',
          'kind': 'objective_success', 'reason': 'objective_conditions_met', 'clock_ms': 548700,
          'seed': 208, 'mode': 'direct', 'difficulty': 'standard'}
INTENT_KEYS = {'campaign_id', 'intent_id', 'generation', 'parent_id', 'parent_digest',
               'policy_digest', 'target_digest', 'c0_sha256', 'confirmed'}


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False, allow_nan=False).encode()


def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def file_sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write(path, value):
    Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def connect(path):
    db = sqlite3.connect(path, timeout=10, isolation_level=None)
    db.execute('PRAGMA synchronous=FULL')
    return db


def initialize(path, policy, prepared):
    ledger = {'consumed': {PARENT['id']: PARENT}, 'latest': {'id': 'unrelated-display-record'}}
    with closing(connect(path)) as db:
        db.executescript('''
            CREATE TABLE authority(campaign TEXT PRIMARY KEY, generation INTEGER NOT NULL,
                parent_id TEXT NOT NULL, ledger TEXT NOT NULL, policy TEXT NOT NULL,
                prepared_artifact_sha TEXT NOT NULL);
            CREATE TABLE transitions(campaign TEXT NOT NULL, parent_id TEXT NOT NULL,
                intent_id TEXT NOT NULL, intent_digest TEXT NOT NULL, response TEXT NOT NULL,
                c0_blob BLOB NOT NULL, c0_sha TEXT NOT NULL, binding TEXT NOT NULL,
                PRIMARY KEY(campaign,parent_id), UNIQUE(campaign,parent_id,intent_id));
        ''')
        db.execute('INSERT INTO authority VALUES(?,9,?,?,?,?)',
                   (CAMPAIGN, PARENT['id'], json.dumps(ledger), json.dumps(policy), file_sha(prepared)))
    return ledger


def apply(path, intent, actor, prepared_path, crash):
    # The authority initialized its preparation registry from a verified engine output.
    # Workers cannot replace that trusted artifact with a caller-asserted "verified" flag.
    if actor != ACTOR:
        return {'error': 'forbidden'}
    if type(intent) is not dict or set(intent) != INTENT_KEYS or intent['campaign_id'] != CAMPAIGN:
        return {'error': 'invalid_intent'}
    if type(intent['intent_id']) is not str or not re.fullmatch('[a-z0-9-]{1,64}', intent['intent_id']):
        return {'error': 'invalid_intent_id'}
    if type(intent['generation']) is not int or intent['confirmed'] is not True:
        return {'error': 'invalid_intent'}

    intent_hash = digest(intent)
    # No engine launch or waiting occurs inside this transaction.
    with closing(connect(path)) as db:
        db.execute('BEGIN IMMEDIATE')
        generation, parent_id, ledger_json, policy_json, expected_preparation = db.execute(
            'SELECT generation,parent_id,ledger,policy,prepared_artifact_sha FROM authority WHERE campaign=?',
            (CAMPAIGN,)).fetchone()
        existing = db.execute('SELECT intent_id,intent_digest,response FROM transitions WHERE campaign=? AND parent_id=?',
                              (CAMPAIGN, intent['parent_id'])).fetchone()
        if existing:
            if existing[0] == intent['intent_id']:
                return json.loads(existing[2]) if existing[1] == intent_hash else {'error': 'intent_conflict'}
            return {'error': 'stale_generation' if intent['generation'] != generation else 'parent_already_transitioned'}
        ledger, policy = json.loads(ledger_json), json.loads(policy_json)
        if (type(policy) is not dict or policy.get('version') != 'cross-counter-local-durable-policy/1'
                or policy.get('eligible_kinds') != ['objective_success']
                or policy.get('eligible_reasons') != ['objective_conditions_met']
                or type(policy.get('target')) is not dict):
            return {'error': 'policy_unapproved'}
        parent = ledger['consumed'].get(parent_id)
        if intent['generation'] != generation:
            return {'error': 'stale_generation'}
        if intent['parent_id'] != parent_id or parent != PARENT or digest(parent) != intent['parent_digest']:
            return {'error': 'parent_mismatch'}
        if parent['kind'] != 'objective_success' or parent['reason'] != 'objective_conditions_met':
            return {'error': 'parent_ineligible'}
        if digest(policy) != intent['policy_digest'] or digest(policy['target']) != intent['target_digest']:
            return {'error': 'policy_target_mismatch'}
        # A historical accepted retry returned above without touching target data.
        # New transitions alone need the registered preparation artifact.
        try:
            prepared_bytes = Path(prepared_path).read_bytes()
            prepared = json.loads(prepared_bytes)
            details = prepared['details']
            blob = base64.b64decode(details['packet_b64'], validate=True)
        except FileNotFoundError:
            return {'error': 'target_unavailable'}
        except (OSError, ValueError, KeyError, TypeError):
            return {'error': 'invalid_prepared_artifact'}
        if hashlib.sha256(prepared_bytes).hexdigest() != expected_preparation:
            return {'error': 'prepared_artifact_mismatch'}
        packet = details['packet']
        target = policy['target']
        if (prepared['status'] != 'PASS' or details['published'] is not False
                or packet['tick'] != 0 or packet['clock_ms'] != 0 or packet['bootstrap_done'] is not False
                or packet['commands'] != [] or packet['pending'] != []
                or packet['request'] != target['request']
                or any(packet[key] != target[key] for key in ('rules_digest','source_digest','effective_digest','state_digest'))):
            return {'error': 'prepared_c0_mismatch'}
        c0_sha = hashlib.sha256(blob).hexdigest()
        if c0_sha != intent['c0_sha256'] or c0_sha != details['binding']['packet_sha256']:
            return {'error': 'prepared_c0_hash_mismatch'}
        transition_id = digest({'schema': 'cross-counter-local-transition/1', 'campaign': CAMPAIGN,
                                'parent_digest': intent['parent_digest'], 'policy_digest': intent['policy_digest']})
        operation_id = DEFINITION + '/' + transition_id
        if packet['operation_id'] != operation_id or details['binding']['operation_id'] != operation_id:
            return {'error': 'prepared_operation_mismatch'}
        response = {'transition_id': transition_id, 'operation_id': operation_id,
                    'generation': generation + 1, 'parent_id': parent_id,
                    'policy_digest': intent['policy_digest'], 'target_digest': intent['target_digest'],
                    'c0_sha256': c0_sha}
        changed = db.execute('UPDATE authority SET generation=? WHERE campaign=? AND generation=? AND parent_id=?',
                             (generation + 1, CAMPAIGN, generation, parent_id))
        if changed.rowcount != 1:
            raise AssertionError('CAS failed inside writer transaction')
        db.execute('INSERT INTO transitions(campaign,parent_id,intent_id,intent_digest,response,c0_blob,c0_sha,binding) VALUES(?,?,?,?,?,?,?,?)',
                   (CAMPAIGN, parent_id, intent['intent_id'], intent_hash, json.dumps(response),
                    sqlite3.Binary(blob), c0_sha, json.dumps(details['binding'])))
        if crash == 'before':
            os._exit(71)
        db.execute('COMMIT')
        if crash == 'after':
            os._exit(72)
        return response


def worker(args):
    if args.gate:
        Path(args.ready).touch(exist_ok=False)
        deadline = time.monotonic() + 10
        while not Path(args.gate).exists():
            if time.monotonic() > deadline:
                raise TimeoutError('worker gate')
            time.sleep(.01)
    reply = apply(args.db, json.loads(args.intent), args.actor, args.prepared, args.crash)
    print(json.dumps({'pid': os.getpid(), 'reply': reply}))


def inspect(path):
    with closing(connect(path)) as db:
        generation, ledger = db.execute('SELECT generation,ledger FROM authority').fetchone()
        rows = db.execute('SELECT response,c0_blob,c0_sha,binding FROM transitions').fetchall()
    return generation, json.loads(ledger), rows


def record(path, actor=ACTOR):
    if actor != ACTOR:
        raise PermissionError('forbidden')
    _, _, rows = inspect(path)
    if len(rows) != 1:
        raise AssertionError('one committed transition required')
    response, blob, sha, binding = rows[0]
    if hashlib.sha256(blob).hexdigest() != sha:
        raise AssertionError('authority blob changed')
    result = json.loads(response)
    result.update(packet_b64=base64.b64encode(blob).decode(), binding=json.loads(binding))
    return result


class Evaluation:
    def __init__(self, args):
        self.args = args
        self.root = args.output.resolve()
        self.root.mkdir(parents=True, exist_ok=False)
        self.checks = []
        self.workers = []
        self.engines = []

    def check(self, label, value):
        self.checks.append({'name': label, 'pass': bool(value)})
        print('CROSS_COUNTER_SQLITE_CHECK', bool(value), label, flush=True)
        if not value:
            raise AssertionError(label)

    def engine(self, name, payload):
        directory = self.root / name
        (directory / 'profile' / 'Roaming').mkdir(parents=True)
        (directory / 'profile' / 'Local').mkdir()
        write(directory / 'input.json', payload)
        env = os.environ.copy()
        env.update(APPDATA=str(directory / 'profile' / 'Roaming'), LOCALAPPDATA=str(directory / 'profile' / 'Local'),
                   SBTK_CROSS_COUNTER_ISOLATED_ROOT=str(directory / 'profile'),
                   SBTK_CROSS_COUNTER_RESULT_DIR=str(directory), SBTK_CROSS_COUNTER_BRIDGE_INPUT=str(directory / 'input.json'))
        command = [str(self.args.engine), '--headless', '--path', str(self.args.worktree), '--script',
                   'res://tests/cross_counter_evaluation_durable_bridge.gd', '--quit-after', '300']
        started = time.time()
        with (directory / 'stdout.log').open('wb') as stdout, (directory / 'stderr.log').open('wb') as stderr:
            process = subprocess.run(command, env=env, stdout=stdout, stderr=stderr, timeout=60,
                                     creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        write(directory / 'run.json', {'command': command, 'exit_code': process.returncode,
                                      'started_unix': started, 'finished_unix': time.time()})
        self.check(name + ': engine exit0 and empty stderr', process.returncode == 0 and (directory / 'stderr.log').stat().st_size == 0)
        result = json.loads((directory / 'result.json').read_text(encoding='utf-8-sig'))
        self.check(name + ': real engine checks pass', result['status'] == 'PASS')
        self.engines.append({'name': name, 'pid': result['pid'], 'checks': result['checks_total']})
        return directory / 'result.json', result

    def launch(self, db, intent, prepared, actor=ACTOR, crash='', gate='', ready=''):
        command = [sys.executable, '-B', __file__, '--worker', '--db', str(db), '--intent', json.dumps(intent),
                   '--prepared', str(prepared), '--actor', actor, '--crash', crash]
        if gate:
            command += ['--gate', str(gate), '--ready', str(ready)]
        return subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                                creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))

    def collect(self, process, expected=0):
        stdout, stderr = process.communicate(timeout=15)
        self.workers.append({'pid': process.pid, 'exit_code': process.returncode, 'stdout': stdout, 'stderr': stderr})
        self.check('independent worker exit and stderr', process.returncode == expected and not stderr)
        if expected:
            self.check('crashed worker returned no response', not stdout)
            return None
        value = json.loads(stdout)
        self.check('worker result binds actual independent PID', value['pid'] == process.pid and process.pid != os.getpid())
        return value['reply']

    def run(self):
        baseline = json.loads(self.args.baseline.read_text(encoding='utf-8-sig'))['snapshots']['c0']
        target = {key: baseline[key] for key in ('request','rules_digest','source_digest','effective_digest','state_digest')}
        target.update(schema='cross-counter-local-durable-target/1', public_activation=False)
        policy = {'version': 'cross-counter-local-durable-policy/1', 'eligible_kinds': ['objective_success'],
                  'eligible_reasons': ['objective_conditions_met'], 'target': target}
        parent_digest, policy_digest = digest(PARENT), digest(policy)
        transition_id = digest({'schema': 'cross-counter-local-transition/1', 'campaign': CAMPAIGN,
                                'parent_digest': parent_digest, 'policy_digest': policy_digest})
        operation_id = DEFINITION + '/' + transition_id
        prepared, proof = self.engine('prepare', {'mode': 'prepare', 'operation_id': operation_id})
        self.check('C0 engine prepared without publication', proof['details']['published'] is False)
        details = proof['details']
        self.check('prepared blob hashes to exact trusted bind',
                   hashlib.sha256(base64.b64decode(details['packet_b64'], validate=True)).hexdigest() == details['binding']['packet_sha256'])
        self.check('prepared real C0 agrees with reviewed restore baseline',
                   all(details['packet'][key] == target[key] for key in ('request','rules_digest','source_digest','effective_digest','state_digest')))
        intent = {'campaign_id': CAMPAIGN, 'intent_id': 'confirm-1', 'generation': 9, 'parent_id': PARENT['id'],
                  'parent_digest': parent_digest, 'policy_digest': policy_digest, 'target_digest': digest(target),
                  'c0_sha256': details['binding']['packet_sha256'], 'confirmed': True}
        write(self.root / 'policy.json', policy)
        write(self.root / 'parent.json', {'synthetic': True, 'facts': PARENT})
        write(self.root / 'intent.json', intent)
        db = self.root / 'restart.sqlite'
        ledger = initialize(db, policy, prepared)
        self.collect(self.launch(db, intent, prepared, crash='before'), 71)
        generation, actual_ledger, rows = inspect(db)
        self.check('before-commit crash rolls back permission and C0 together', generation == 9 and actual_ledger == ledger and not rows)
        self.collect(self.launch(db, intent, prepared, crash='after'), 72)
        generation, actual_ledger, rows = inspect(db)
        self.check('after-commit response loss retains one C0 and next generation', generation == 10 and actual_ledger == ledger and len(rows) == 1)
        first = self.collect(self.launch(db, intent, prepared))
        second = self.collect(self.launch(db, intent, prepared))
        self.check('restarted authority returns identical operation and C0 hash', first == second and first['operation_id'] == operation_id and first['c0_sha256'] == intent['c0_sha256'])
        missing = self.root / 'missing-prepared.json'
        self.check('historical retry survives missing target preparation artifact',
                   self.collect(self.launch(db, intent, missing)) == first)
        absent_db = self.root / 'new-target-unavailable.sqlite'
        initialize(absent_db, policy, prepared)
        self.check('new transition fails closed when target preparation is unavailable',
                   self.collect(self.launch(absent_db, intent, missing)) == {'error':'target_unavailable'})
        absent_gen, absent_ledger, absent_rows = inspect(absent_db)
        self.check('unavailable target creates no permission or generation',
                   absent_gen == 9 and absent_ledger == ledger and not absent_rows)
        withdrawn_db = self.root / 'withdrawn-policy.sqlite'
        initialize(withdrawn_db, policy, prepared)
        with closing(connect(withdrawn_db)) as connection:
            connection.execute("UPDATE authority SET policy='null'")
        self.check('withdrawn candidate policy rejects new transition',
                   self.collect(self.launch(withdrawn_db, intent, prepared)) == {'error':'policy_unapproved'})
        withdrawn_gen, withdrawn_ledger, withdrawn_rows = inspect(withdrawn_db)
        self.check('withdrawn policy leaves generation and parent intact',
                   withdrawn_gen == 9 and withdrawn_ledger == ledger and not withdrawn_rows)
        changed = dict(intent, c0_sha256='0' * 64)
        self.check('changed same-key retry conflicts', self.collect(self.launch(db, changed, prepared)) == {'error': 'intent_conflict'})
        self.check('unauthorized historical response is fenced first', self.collect(self.launch(db, intent, prepared, actor='untrusted')) == {'error': 'forbidden'})
        self.check('different key at old generation is stale', self.collect(self.launch(db, dict(intent, intent_id='confirm-2'), prepared)) == {'error': 'stale_generation'})
        self.check('different key after refresh cannot reuse parent', self.collect(self.launch(db, dict(intent, intent_id='confirm-2', generation=10), prepared)) == {'error': 'parent_already_transitioned'})
        saved_record = record(db)
        db_sha = file_sha(db)
        _, restored = self.engine('consume-after-response-loss', {'mode': 'restore', 'authority_committed': True, 'record': saved_record})
        self.check('committed actual C0 validates detached then publishes', restored['details']['published'] is True and restored['details']['packet_sha256'] == first['c0_sha256'])
        damaged = json.loads(json.dumps(saved_record))
        damaged['binding']['packet_sha256'] = '0' * 64
        _, rejected = self.engine('bad-candidate', {'mode': 'restore', 'authority_committed': True, 'record': damaged, 'expect_rejection': True})
        self.check('bad restore preserves live owner and durable authority', rejected['details']['old_owner_unchanged'] is True and rejected['details']['published'] is False and file_sha(db) == db_sha)
        _, restarted = self.engine('consume-new-process', {'mode': 'restore', 'authority_committed': True, 'record': record(db)})
        self.check('new Godot PID reconstructs identical committed C0', restarted['pid'] != restored['pid'] and restarted['details'] == restored['details'])
        self.check('engine publication does not mutate source authority or parent', file_sha(db) == db_sha and inspect(db)[1] == ledger)
        for mode in ('same', 'different'):
            race_dir = self.root / ('race-' + mode)
            race_dir.mkdir()
            race_db = race_dir / 'authority.sqlite'
            initialize(race_db, policy, prepared)
            gate = race_dir / 'go'
            ready = [race_dir / 'ready-a', race_dir / 'ready-b']
            another = intent if mode == 'same' else dict(intent, intent_id='confirm-2')
            workers = [self.launch(race_db, item, prepared, gate=gate, ready=mark)
                       for item, mark in zip((intent, another), ready)]
            deadline = time.monotonic() + 10
            while not all(path.exists() for path in ready):
                if time.monotonic() > deadline: raise TimeoutError('race readiness')
                time.sleep(.01)
            self.check('race uses two independent local PIDs', workers[0].pid != workers[1].pid)
            gate.touch(exist_ok=False)
            replies = [self.collect(worker) for worker in workers]
            if mode == 'same':
                self.check('same-key concurrent requests return one identical C0', replies[0] == replies[1] == first)
            else:
                self.check('different-key concurrent requests permit one transition',
                           sum('operation_id' in reply for reply in replies) == 1 and {'error':'stale_generation'} in replies)
            gen, stored, rows = inspect(race_db)
            self.check('concurrent C0 blob and permission are one atomic row', gen == 10 and len(rows) == 1 and stored == ledger and hashlib.sha256(rows[0][1]).hexdigest() == intent['c0_sha256'])
        result = {'schema':'cross-counter-durable-restart-proof/1','status':'PASS','checks_passed':len(self.checks),
                  'checks_total':len(self.checks),'checks':self.checks,'engines':self.engines,'workers':self.workers,
                  'operation_id':operation_id,'c0_sha256':intent['c0_sha256'],'rules_digest':target['rules_digest'],
                  'synthetic_parent':True,'real_child_engine_c0':True,'single_pc':True,'public_activation':False,
                  'existing_user_saves_accessed':False,'real_service_authentication':False,'active_owner_lease_tested':False,
                  'python':sys.version.split()[0],'sqlite':sqlite3.sqlite_version}
        write(self.root/'result.json',result)
        print('CROSS_COUNTER_DURABLE_RESULT PASS',len(self.checks),'/',len(self.checks),flush=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--worker',action='store_true')
    parser.add_argument('--db',type=Path)
    parser.add_argument('--intent')
    parser.add_argument('--prepared',type=Path)
    parser.add_argument('--actor',default=ACTOR)
    parser.add_argument('--crash',default='')
    parser.add_argument('--gate',default='')
    parser.add_argument('--ready',default='')
    parser.add_argument('--output',type=Path)
    parser.add_argument('--engine',type=Path)
    parser.add_argument('--worktree',type=Path)
    parser.add_argument('--baseline',type=Path)
    args=parser.parse_args()
    worker(args) if args.worker else Evaluation(args).run()

if __name__=='__main__': main()
