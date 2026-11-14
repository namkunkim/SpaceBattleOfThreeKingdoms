"""Isolated publication ordering with real checkpoints and existing Win32 exclusion.
No product principal, takeover policy, lifetime lease, or public entry is introduced.
"""
import argparse
import base64
from contextlib import closing
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import time

import cross_counter_owner_fencing as fence
from cross_counter_owner_fencing import durable


def lock_path(db):
    return str(Path(db).resolve()) + '.publish.lock'


def guarded(db, action):
    # Same Win32 API/flags as O07Win32.acquire. Every head mutation uses this guard.
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    create = kernel.CreateFileW
    create.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD, ctypes.c_void_p,
                       wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
    create.restype = wintypes.HANDLE
    close = kernel.CloseHandle
    close.argtypes, close.restype = [wintypes.HANDLE], wintypes.BOOL
    handle = create(lock_path(db), 0xC0000000, 0, None, 4, 0, None)
    if handle == ctypes.c_void_p(-1).value:
        error = ctypes.get_last_error()
        return {'error': 'publication_busy' if error == 32 else 'publication_lock_failed', 'win32_error': error}
    try:
        return action()
    finally:
        if not close(handle):
            raise OSError(ctypes.get_last_error(), 'CloseHandle')


def transfer(db, current, owner):
    return guarded(db, lambda: fence.transfer(db, current, owner))


def commit(db, current, intent):
    return guarded(db, lambda: fence.fenced(db, current, 'commit', intent))


def authority_read(db, current):
    # Internal helper called while the engine holds the native OS mutex.
    # Do not reacquire that mutex here. This is not a product-accessible RPC.
    reply = fence.fenced(db, current, 'read')
    result = {'pid': os.getpid(), 'transaction_closed': True}
    if 'error' in reply:
        return dict(result, error=reply['error'])
    return dict(result, operation_id=reply['operation_id'], checkpoint_sha=reply['binding']['packet_sha256'],
                revision=reply['revision'])


class Engine(fence.Engine):
    def __init__(self, run, label):
        self.run, self.label, self.seq = run, label, 0
        self.directory = run.root / label
        (self.directory / 'profile' / 'Roaming').mkdir(parents=True)
        (self.directory / 'profile' / 'Local').mkdir()
        env = dict(os.environ, APPDATA=str(self.directory / 'profile' / 'Roaming'),
                   LOCALAPPDATA=str(self.directory / 'profile' / 'Local'),
                   SBTK_CROSS_COUNTER_ISOLATED_ROOT=str(self.directory / 'profile'),
                   SBTK_CROSS_COUNTER_RESULT_DIR=str(self.directory), SBTK_CROSS_COUNTER_OPERATION_ID=fence.OPERATION,
                   SBTK_PUBLICATION_DB=str(run.db), SBTK_PUBLICATION_PYTHON=sys.executable)
        self.command = [str(run.args.engine), '--headless', '--max-fps', '60', '--path', str(run.args.worktree),
                        '--script', 'res://tests/cross_counter_publication_guard.gd']
        self.started = time.time()
        self.stdout, self.stderr = [(self.directory / name).open('wb') for name in ['stdout.log', 'stderr.log']]
        self.process = subprocess.Popen(self.command, env=env, stdout=self.stdout, stderr=self.stderr,
                                        creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        run.engines.append(self)
        self.ready = self.wait('ready.json')
        self.pid, self.owner = self.ready['pid'], label + '-' + str(self.ready['pid'])
        run.check(label + ': fresh profile and no installed owner', self.ready['live'] is False
                  and Path(self.ready['user_data_dir']).is_relative_to(self.directory / 'profile'))

    def prepare(self, record, current):
        _, result = self.call('prepare_install', record=record, fence_json=json.dumps(current))
        self.run.check(self.label + ': actual native replay completes before publication mutex',
                       result['ok'] and result['published'] is False and result['packet_sha256'] == record['binding']['packet_sha256'])
        return result

    def publish(self, case):
        _, result = self.call('publish_guarded', case=case)
        self.run.publications.append({'engine': self.label, 'case': case, 'reply': result})
        return result

    def install(self, record, current, case):
        self.prepare(record, current)
        result = self.publish(case)
        self.run.check(case + ': checked checkpoint installed', result['ok']
                       and result['observation']['packet_sha256'] == record['binding']['packet_sha256'])
        return result['observation']

    def stage(self, db, current, name, plan):
        path, result = self.call('stage', base_sha=current['checkpoint_sha'], plan=plan)
        self.run.check(name + ': detached update preserves live checkpoint', result['ok']
                       and result['old_observation']['packet_sha256'] == current['checkpoint_sha'])
        intent = guarded(db, lambda: fence.register_proposal(db, current, name, path, self.pid))
        assert 'error' not in intent
        return intent, result

    def begin_contended_publication(self):
        self.seq += 1
        temporary = self.directory / ('request-%03d.tmp' % self.seq)
        durable.write(temporary, {'action': 'publish_guarded', 'case': 'publication-before-transfer',
                                 'barrier': 'contending-transfer'})
        temporary.replace(self.directory / ('request-%03d.json' % self.seq))
        return self.wait('publication-entered.json')

    def release_contended_publication(self):
        temporary = self.directory / 'publication-release.tmp'
        durable.write(temporary, {'release': True})
        temporary.replace(self.directory / 'publication-release.json')
        result = self.wait('response-%03d.json' % self.seq)
        assert result['sequence'] == self.seq and result['pid'] == self.pid
        self.run.publications.append({'engine': self.label, 'case': 'publication-before-transfer', 'reply': result})
        return result


class Run(fence.Run):
    def __init__(self, args):
        super().__init__(args)
        self.db = self.root / 'authority.sqlite'
        self.publications = []

    def transfer_worker(self, current, new_owner):
        command = [sys.executable, '-B', __file__, '--transfer-worker', '--db', str(self.db),
                   '--fence', json.dumps(current), '--new-owner', new_owner]
        value = subprocess.run(command, capture_output=True, text=True, timeout=15,
                               creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        result = json.loads(value.stdout)
        self.workers.append({'command': command, 'stdout': value.stdout, 'stderr': value.stderr,
                             'exit_code': value.returncode, 'pid': result['pid'], 'reply': result['reply']})
        self.check('independent transfer worker exits normally', value.returncode == 0 and not value.stderr)
        return result

    def execute(self):
        record = fence.source_record(self.args.source_db)
        durable.write(self.root / 'source-c0.json', record)
        a, b = Engine(self, 'engine-a'), Engine(self, 'engine-b')
        self.check('two distinct actual Godot PIDs are simultaneously alive', a.pid != b.pid
                   and a.process.poll() is None and b.process.poll() is None)
        guarded(self.db, lambda: fence.initialize(self.db, record, a.owner))
        fa = {'operation_id': fence.OPERATION, 'owner_id': a.owner, 'epoch': 1, 'checkpoint_sha': fence.C0_SHA}
        a_c0 = a.install(record, fa, 'initial-c0')
        self.check('real committed C0 is unstarted and has no native commands',
                   a_c0['packet']['tick'] == 0 and a_c0['packet']['bootstrap_done'] is False
                   and a_c0['native_witness']['command_log'] == [])
        _, bypass = a.call('install', fixture_authority_validated=True, record=record)
        self.check('old coordinator-assertion installation route is disabled in this adapter',
                   bypass.get('error') == 'unguarded_install_disabled')

        # Prepare from a valid read, then change only the head under the same owner/epoch.
        intent, candidate = a.stage(self.db, fa, 'a-start-pending', 'start_pending')
        a.prepare(fence.fenced(self.db, fa, 'read'), fa)
        accepted = commit(self.db, fa, intent)
        self.check('started pending checkpoint commits before delayed publication', accepted.get('revision') == 1)
        after_commit = durable.file_sha(self.db)
        stale_head = a.publish('same-epoch-head-changed')
        self.check('same-owner old read cannot publish after checkpoint head changes',
                   stale_head.get('error') == 'stale_checkpoint' and stale_head['observation'] == a_c0
                   and durable.file_sha(self.db) == after_commit)
        fa = dict(fa, checkpoint_sha=intent['candidate_sha'])
        record_s1 = fence.fenced(self.db, fa, 'read')
        a_s1 = a.install(record_s1, fa, 'a-started-pending')
        self.check('installed S1 retains one pending stop and two bootstrap native commands',
                   a_s1['packet']['tick'] == 1 and len(a_s1['packet']['pending']) == 1
                   and a_s1['packet']['pending'][0]['kind'] == 'stop'
                   and len(a_s1['native_witness']['command_log']) == 2)

        # Real epoch handoff after prepare/read, before final publication.
        a.prepare(record_s1, fa)
        fb = transfer(self.db, fa, b.owner)
        self.check('explicit fixture owner handoff changes epoch while preserving head',
                   fb == dict(fa, owner_id=b.owner, epoch=2))
        after_transfer = durable.file_sha(self.db)
        stale_owner = a.publish('transfer-before-publication')
        self.check('revoked prepared owner cannot publish a formerly authorized read',
                   stale_owner.get('error') == 'stale_owner' and stale_owner['observation'] == a_s1
                   and durable.file_sha(self.db) == after_transfer)
        b_s1 = b.install(fence.fenced(self.db, fb, 'read'), fb, 'new-owner-restart')
        self.check('new PID installs exact started checkpoint and pending native witness',
                   b_s1['packet_sha256'] == a_s1['packet_sha256']
                   and b_s1['native_witness'] == a_s1['native_witness'])

        # The opposite ordering: publication owns the native lock before transfer attempts.
        b.prepare(record_s1, fb)
        entered = b.begin_contended_publication()
        self.check('publication entered its mutex after a separate closed-transaction authority read',
                   entered['pid'] == b.pid and entered['authority_pid'] not in [a.pid, b.pid, os.getpid()]
                   and entered['transaction_closed'] is True)
        # Independently obtain the SQLite writer lock while Godot still holds the OS mutex.
        # This diagnostic writes no data and deliberately does not mutate authority state.
        with closing(sqlite3.connect(self.db, timeout=.1, isolation_level=None)) as probe:
            probe.execute('BEGIN IMMEDIATE')
            probe.execute('ROLLBACK')
        self.check('SQLite transaction is actually closed while publication holds only OS mutex', True)
        busy = self.transfer_worker(fb, a.owner)
        self.check('concurrent transfer fails busy under the same native Windows lock',
                   busy['reply'] == {'error': 'publication_busy', 'win32_error': 32})
        self.check('contending transfer and read-only SQLite probe leave head bytes unchanged',
                   durable.file_sha(self.db) == after_transfer)
        legal = b.release_contended_publication()
        self.check('legal publication completes before the blocked handoff retries', legal['ok']
                   and legal['observation']['packet_sha256'] == b_s1['packet_sha256']
                   and legal['observation']['native_instance_id'] != b_s1['native_instance_id'])
        retried = self.transfer_worker(fb, a.owner)
        fa2 = retried['reply']
        self.check('released mutex permits one valid owner transfer', fa2 == dict(fb, owner_id=a.owner, epoch=3))
        a_final = a.install(fence.fenced(self.db, fa2, 'read'), fa2, 'new-epoch-owner-resume')
        self.check('post-publication new owner resumes the same persisted pending state',
                   a_final['packet_sha256'] == a_s1['packet_sha256'] and a_final['native_witness'] == a_s1['native_witness'])

        # Rejection/cancel are publication-lifecycle checks, not a full restore rerun.
        preserved = durable.file_sha(self.db)
        bad = json.loads(json.dumps(record_s1))
        bad['binding']['packet_sha256'] = '0' * 64
        _, rejected = a.call('prepare_install', record=bad, fence_json=json.dumps(fa2))
        self.check('bad bind cannot prepare or replace the current owner', not rejected['ok']
                   and rejected['observation'] == a_final)
        a.prepare(record_s1, fa2)
        _, cancelled = a.call('cancel')
        _, no_candidate = a.call('publish_guarded', case='cancelled')
        self.check('cancel closes the detached candidate without changing the current owner',
                   cancelled['observation'] == a_final and no_candidate.get('error') == 'publication_not_prepared'
                   and durable.file_sha(self.db) == preserved)
        with closing(durable.connect(self.db)) as db:
            counts = {name: db.execute('SELECT COUNT(*) FROM ' + name).fetchone()[0]
                      for name in ['checkpoints', 'receipts', 'transfers', 'proposals']}
            head = db.execute('SELECT owner,epoch,revision,checkpoint_sha FROM head').fetchone()
            self.check('publication adds no checkpoint effect or duplicate bootstrap',
                       counts == {'checkpoints': 2, 'receipts': 1, 'transfers': 2, 'proposals': 1}
                       and head == (a.owner, 3, 1, a_final['packet_sha256'])
                       and db.execute('PRAGMA integrity_check').fetchone() == ('ok',))
        engines = [engine.finish() for engine in self.engines]
        self.check('prior immutable actual-parent database is unchanged',
                   durable.file_sha(self.args.source_db) == fence.SOURCE_DB_SHA)
        durable.write(self.root / 'workers.json', self.workers)
        durable.write(self.root / 'publication-records.json', self.publications)
        ordinary = [row['reply']['mutex_usec'] for row in self.publications
                    if row['case'] != 'publication-before-transfer']
        barrier = next(row['reply'] for row in self.publications if row['case'] == 'publication-before-transfer')
        return {'schema': 'cross-counter-publication-guard-proof/1', 'status': 'PASS',
                'checks_total': len(self.checks), 'checks_passed': len(self.checks), 'checks': self.checks,
                'engines': engines, 'workers': [x['pid'] for x in self.workers],
                'source_db_sha256': fence.SOURCE_DB_SHA, 'database_sha256': durable.file_sha(self.db),
                'counts': counts, 'head': list(head), 'ordinary_mutex_usec': ordinary,
                'barrier_mutex_usec': barrier['mutex_usec'], 'intentional_barrier_usec': barrier['barrier_usec'],
                'single_pc': True, 'public_activation': False, 'real_service_authentication': False,
                'lifetime_owner_exclusion': False, 'scope': 'Final publication order under shared local mutex; not post-handoff UI eviction.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--authority-read', action='store_true')
    parser.add_argument('--transfer-worker', action='store_true')
    for name in ['db', 'fence', 'fence-b64', 'new-owner']:
        parser.add_argument('--' + name)
    for name in ['engine', 'worktree', 'source-db', 'output']:
        parser.add_argument('--' + name, type=Path)
    args = parser.parse_args()
    if args.authority_read:
        print(json.dumps(authority_read(args.db, json.loads(base64.b64decode(args.fence_b64, validate=True)))))
        return
    if args.transfer_worker:
        print(json.dumps({'pid': os.getpid(), 'reply': transfer(args.db, json.loads(args.fence), args.new_owner)}))
        return
    for name in ['engine', 'worktree', 'source_db', 'output']:
        if getattr(args, name) is None:
            parser.error('--' + name.replace('_', '-') + ' is required')
    run = Run(args)
    try:
        result = run.execute()
    except Exception as error:
        durable.write(run.root / 'result.json', {'status': 'FAIL', 'error': repr(error), 'checks': run.checks})
        for engine in run.engines:
            if engine.process.poll() is None:
                try:
                    release = engine.directory / 'publication-release.json'
                    if not release.exists(): durable.write(release, {'release': True})
                    engine.call('shutdown')
                    engine.process.wait(timeout=15)
                except Exception:
                    engine.process.terminate()
        raise
    durable.write(run.root / 'result.json', result)
    print('CROSS_COUNTER_PUBLICATION_GUARD PASS', result['checks_total'], flush=True)


if __name__ == '__main__':
    main()
