"""Private Cross Counter host: real UI signals, guarded authority, isolated saves.
The current evaluation roster and command contract are unchanged. No product admission or settlement.
"""
import argparse
import base64
from contextlib import closing
import json
import os
from pathlib import Path
import subprocess
import sys
import time

import cross_counter_publication_guard as publication
from cross_counter_publication_guard import fence, durable


def helper(args):
    current = json.loads(base64.b64decode(args.fence_b64, validate=True))
    if args.helper == 'read':
        record = fence.fenced(args.db, current, 'read')
        return dict(record, ok=False) if 'error' in record else {'ok': True, 'record': record, 'transaction_closed': True}
    def save():
        record = fence.fenced(args.db, current, 'read')
        if 'error' in record:
            return dict(record, ok=False)
        artifact = fence.read(args.artifact)
        assert artifact['ok'] is True and artifact['published'] is False and artifact['pid'] == args.engine_pid
        assert artifact['base_sha'] == current['checkpoint_sha']
        if artifact['binding']['packet_sha256'] == current['checkpoint_sha']:
            return {'ok': True, 'unchanged': True, 'fence_json': json.dumps(current)}
        intent = fence.register_proposal(args.db, current, args.intent, args.artifact, args.engine_pid)
        if 'error' in intent:
            return dict(intent, ok=False)
        accepted = fence.fenced(args.db, current, 'commit', intent)
        if 'error' in accepted:
            return dict(accepted, ok=False)
        refreshed = dict(current, checkpoint_sha=accepted['checkpoint_sha'])
        return {'ok': True, 'unchanged': False, 'fence_json': json.dumps(refreshed), 'receipt': accepted}
    reply = publication.guarded(args.db, save)
    return dict(reply, ok=False) if 'error' in reply else reply


class Engine(publication.Engine):
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
        display = ['--rendering-method', 'gl_compatibility', '--position', '40,40'] if run.args.render else ['--headless']
        self.command = [str(run.args.engine), *display, '--max-fps', '60', '--path', str(run.args.worktree),
                        '--script', 'res://tests/cross_counter_evaluation_host_probe.gd']
        self.started = time.time()
        self.stdout, self.stderr = [(self.directory / name).open('wb') for name in ['stdout.log', 'stderr.log']]
        self.process = subprocess.Popen(self.command, env=env, stdout=self.stdout, stderr=self.stderr,
                                        creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        run.engines.append(self)
        self.ready = self.wait('ready.json')
        self.pid, self.owner = self.ready['pid'], label + '-' + str(self.ready['pid'])
        run.check(label + ': fresh isolated profile', Path(self.ready['user_data_dir']).is_relative_to(self.directory / 'profile'))

    def observe(self):
        return self.call('host_observe')[1]

    def ui(self, control, **kwargs):
        result = self.call('host_control', control=control, **kwargs)[1]
        self.run.ui_events.append({'engine': self.label, 'control': control, 'sequence': self.seq,
                                   'ok': result['ok'], 'tick': result['observation']['packet']['tick']})
        return result

    def capture(self, name):
        response = self.call('capture', name=name)[1]
        if response['rendered']:
            result = self.wait(name + '-capture.json')
            self.run.check(name + ': rendered private viewport is 1600x900 in the same engine PID',
                           result['ok'] and result['pid'] == self.pid and (result['width'], result['height']) == (1600, 900))
            self.run.captures.append(dict(result, file=str(self.directory / (name + '.png'))))


class Run(publication.Run):
    def __init__(self, args):
        super().__init__(args)
        self.ui_events, self.captures = [], []

    def coherent(self, value, label):
        model, diagnostic = value['host']['model'], value['observation']
        packet, native = diagnostic['packet'], diagnostic['native_witness']
        self.check(label + ': visible model matches real owner clock, queue and fleet projection',
                   model['tick'] == packet['tick'] and model['clock_ms'] == packet['clock_ms']
                   and model['operation_id'] == packet['operation_id'] and model['pending_count'] == len(packet['pending'])
                   and model['history_batches'] == len(packet['commands'])
                   and [(f['id'], f['pos'], f['ships_milli']) for f in model['fleets']]
                   == [(f['id'], f['pos'], f['ships']) for f in native['fleets']])

    def execute(self):
        record = fence.source_record(self.args.source_db)
        durable.write(self.root / 'source-c0.json', record)
        a = Engine(self, 'engine-a')
        publication.guarded(self.db, lambda: fence.initialize(self.db, record, a.owner))
        fa = {'operation_id': fence.OPERATION, 'owner_id': a.owner, 'epoch': 1, 'checkpoint_sha': fence.C0_SHA}
        a.install(record, fa, 'host-c0')
        c0 = a.observe()
        self.coherent(c0, 'C0')
        self.check('C0 controls start paused with two 60-ship fleets and no bootstrap',
                   c0['host']['paused'] and c0['host']['controls']['step']['disabled']
                   and [x['ships_milli'] for x in c0['host']['model']['fleets']] == [60000, 60000]
                   and not c0['observation']['packet']['bootstrap_done'])
        blocked = a.ui('step')
        self.check('paused step control cannot change native C0', not blocked['ok']
                   and blocked['result']['error'] == 'control_disabled' and blocked['observation'] == c0['observation'])
        a.capture('c0')
        begun = a.ui('begin')
        repeated = a.ui('begin')
        self.check('actual begin button issues two native moves only once', begun['ok'] and repeated['ok']
                   and len(begun['observation']['native_witness']['command_log']) == 2
                   and repeated['observation'] == begun['observation'])
        moved = a.ui('move', x=900, y=500)
        self.check('move button queues an operation-bound real pending command', moved['ok']
                   and [x['kind'] for x in moved['observation']['packet']['pending']] == ['move'])
        saved0 = a.ui('save')
        self.check('save button commits started tick0 with pending move', saved0['ok']
                   and saved0['result']['receipt']['revision'] == 1)
        fa = json.loads(saved0['result']['fence_json'])
        tick1 = a.ui('step')
        self.coherent(tick1, 'First step')
        self.check('step consumes the UI move once through normal owner API', tick1['ok']
                   and tick1['observation']['packet']['tick'] == 1 and tick1['observation']['packet']['pending'] == []
                   and len(tick1['observation']['native_witness']['command_log']) == 3)
        a.ui('pause')
        paused_before = a.observe()
        paused_step = a.ui('step')
        self.check('pause prevents the next tick and preserves native witness', not paused_step['ok']
                   and paused_step['observation'] == paused_before['observation'])
        stopped = a.ui('stop')
        saved1 = a.ui('save')
        self.check('stop and save buttons persist tick1 with one pending stop', stopped['ok'] and saved1['ok']
                   and saved1['result']['receipt']['revision'] == 2
                   and [x['kind'] for x in saved1['observation']['packet']['pending']] == ['stop'])
        fa = json.loads(saved1['result']['fence_json'])
        committed_s1 = fence.fenced(self.db, fa, 'read')
        unsaved = a.ui('move', x=1000, y=550)
        self.check('new unsaved input remains distinct from the persisted head', unsaved['ok']
                   and [x['kind'] for x in unsaved['observation']['packet']['pending']] == ['stop', 'move'])
        a.prepare(committed_s1, fa)
        _, cancel = a.call('cancel')
        self.check('cancelled UI restore preserves unsaved pending native state and displayed model',
                   cancel['observation'] == unsaved['observation'] and cancel['host']['model'] == unsaved['host']['model'])
        bad = json.loads(json.dumps(committed_s1))
        bad['binding']['packet_sha256'] = '0' * 64
        _, rejected = a.call('prepare_install', record=bad, fence_json=json.dumps(fa))
        self.check('bad restore bind preserves both owner and host model', not rejected['ok']
                   and rejected['observation'] == unsaved['observation'] and rejected['host']['model'] == unsaved['host']['model'])

        b = Engine(self, 'engine-b')
        self.check('second actual engine PID overlaps the first', a.pid != b.pid and a.process.poll() is None)
        a.prepare(committed_s1, fa)
        fb = publication.transfer(self.db, fa, b.owner)
        before_denials = durable.file_sha(self.db)
        stale = a.publish('stale-host-publication')
        self.check('stale final publication preserves both visible model and native owner',
                   stale.get('error') == 'stale_owner' and stale['observation'] == unsaved['observation']
                   and stale['host']['model'] == unsaved['host']['model'])
        for action in ['begin', 'move', 'save']:
            denied = a.ui(action)
            self.check('stale host ' + action + ' is rejected without native/model mutation',
                       not denied['ok'] and denied['result']['error'] == 'stale_owner'
                       and denied['observation'] == unsaved['observation'] and denied['host']['model'] == unsaved['host']['model'])
        self.check('all stale host requests preserve database bytes', durable.file_sha(self.db) == before_denials)
        b.install(fence.fenced(self.db, fb, 'read'), fb, 'host-new-pid-restore')
        restored = b.observe()
        self.coherent(restored, 'New PID restore')
        self.check('new host restores exact saved packet and starts paused', restored['host']['paused']
                   and restored['observation']['packet_sha256'] == saved1['observation']['packet_sha256']
                   and restored['observation']['native_witness'] == saved1['observation']['native_witness'])
        b.capture('restored')
        resumed = b.ui('begin')
        tick2 = b.ui('step')
        self.check('resumed UI consumes pending stop once without bootstrap replay', resumed['ok'] and tick2['ok']
                   and tick2['observation']['packet']['tick'] == 2 and tick2['observation']['packet']['pending'] == []
                   and len(tick2['observation']['native_witness']['command_log']) == 4
                   and [r['batch'][0]['kind'] for r in tick2['observation']['packet']['commands']] == ['move', 'stop'])
        saved2 = b.ui('save')
        same_save = b.ui('save')
        self.check('save and repeated unchanged save produce one new durable checkpoint', saved2['ok']
                   and saved2['result']['receipt']['revision'] == 3 and same_save['ok'] and same_save['result']['unchanged'])
        fb = json.loads(saved2['result']['fence_json'])
        tick3 = b.ui('step')
        self.check('next UI tick does not repeat already consumed commands', tick3['ok']
                   and tick3['observation']['native_witness']['command_log'] == tick2['observation']['native_witness']['command_log'])
        loaded = b.ui('load')
        self.check('actual restore button returns to saved tick2 with a new native instance', loaded['ok']
                   and loaded['host']['paused'] and loaded['observation']['packet_sha256'] == saved2['observation']['packet_sha256']
                   and loaded['observation']['native_instance_id'] != tick3['observation']['native_instance_id'])
        b.ui('begin')
        replayed3 = b.ui('step')
        self.coherent(replayed3, 'Host restore and next step')
        self.check('same host restore reproduces exact tick3 native witness',
                   replayed3['observation']['native_witness'] == tick3['observation']['native_witness'])
        b.capture('progressed')
        with closing(durable.connect(self.db)) as db:
            counts = {name: db.execute('SELECT COUNT(*) FROM ' + name).fetchone()[0]
                      for name in ['checkpoints', 'receipts', 'transfers', 'proposals']}
            self.check('UI effects produce only expected checkpoint/receipt/transfer counts',
                       counts == {'checkpoints': 4, 'receipts': 3, 'transfers': 1, 'proposals': 3}
                       and db.execute('PRAGMA integrity_check').fetchone() == ('ok',))
        engines = [engine.finish() for engine in self.engines]
        self.check('prior actual-parent source database is unchanged', durable.file_sha(self.args.source_db) == fence.SOURCE_DB_SHA)
        durable.write(self.root / 'ui-events.json', self.ui_events)
        durable.write(self.root / 'publication-records.json', self.publications)
        return {'schema': 'cross-counter-private-host-proof/1', 'status': 'PASS', 'checks': self.checks,
                'checks_total': len(self.checks), 'checks_passed': len(self.checks), 'engines': engines,
                'rendered': self.args.render, 'captures': self.captures, 'ui_control_attempt_count': len(self.ui_events),
                'database_sha256': durable.file_sha(self.db), 'source_db_sha256': fence.SOURCE_DB_SHA,
                'counts': counts, 'final_fence': fb, 'public_activation': False, 'new_settlement_policy': False,
                'existing_user_saves_accessed': False, 'scope': 'Private projection host, owner API controls and explicit logical single-tick stepping.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--helper', choices=['read', 'save'])
    for name in ['db', 'fence-b64', 'artifact', 'intent']:
        parser.add_argument('--' + name)
    parser.add_argument('--engine-pid', type=int)
    parser.add_argument('--render', action='store_true')
    for name in ['engine', 'worktree', 'source-db', 'output']:
        parser.add_argument('--' + name, type=Path)
    args = parser.parse_args()
    if args.helper:
        print(json.dumps(helper(args)))
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
                    engine.call('shutdown')
                    engine.process.wait(timeout=15)
                except Exception:
                    engine.process.terminate()
        raise
    durable.write(run.root / 'result.json', result)
    print('CROSS_COUNTER_PRIVATE_HOST PASS', result['checks_total'], flush=True)


if __name__ == '__main__':
    main()
