"""Additive, single-PC integration of a pinned real parent with the reviewed evaluator.
The imported module's test fixture PARENT is bound once per process. Its source is unchanged.
This is not a product authority, authenticated service, or public successor entry point.
"""
import argparse
import base64
from contextlib import closing
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess
import sys

import cross_counter_evaluation_durable as durable

PARENT_DIGEST = '94161d7b3c2840a40fdd65f14578e3a399424819d12a3f688c8104060a4ef595'
BASELINE_SHA = 'ad2ce398bae617fd84b6ff45b65b7bc7db774cd055ad4e59c1bd548811725d46'
PINS = {
    'parent-fixture.json': '5b531a5da94a0f8512119db30da75c7b42f8418e9a9a5d163d293435aeef457c',
    'generate-result.json': '7642378870a1ba3a858eaf4f1cd966433d5799795e73eef3c0de7a41a75aa697',
    'reopen-result.json': '7407f3a9eb198bbd016107f0c950947b154a5c4dd6a731aecfc7f366a130d211',
    'parent-run.json': '34fbc92f4ecddbc50df84e42083db3c0e92cd4d95ee79555021b7157096e4326',
    'parent-ledger.save': 'adb0e006848ed1be5cdb0749d634701eb2a2d99802fa0fb58f0d2296b32be3bf',
}
PARENT_KEYS = {'id', 'kind', 'reason', 'clock_ms', 'seed', 'mode', 'difficulty'}


class ParentRejected(ValueError):
    pass


def require(condition, reason):
    if not condition:
        raise ParentRejected(reason)


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def canonical_parent(value):
    require(type(value) is dict and set(value) == PARENT_KEYS, 'invalid_parent_fields')
    result = value.copy()
    for key in PARENT_KEYS - {'clock_ms', 'seed'}:
        require(type(result[key]) is str, 'invalid_parent_string')
    require(re.fullmatch('red-cliffs-first-operation-dev-v1/[0-9a-f]{32}/settlement', result['id']), 'invalid_parent_id')
    for key in ('clock_ms', 'seed'):
        item = result[key]
        require(type(item) in (int, float) and math.isfinite(item) and abs(item) <= 9007199254740991
                and item == int(item), 'invalid_parent_integer')
        result[key] = int(item)
    require(result['clock_ms'] >= 0 and result['mode'] in ('direct', 'auto')
            and result['difficulty'] and result['reason'], 'invalid_parent_value')
    return result


def validate_parent(directory):
    directory = Path(directory)
    for name, expected in PINS.items():
        require(durable.file_sha(directory / name) == expected, 'parent_artifact_mismatch')
    fixture, generated, reopened, observed = [read(directory / name) for name in
                                             ('parent-fixture.json', 'generate-result.json', 'reopen-result.json', 'parent-run.json')]
    envelope = read(directory / 'parent-ledger.save')
    require(envelope['format'] == 'pc-first-operation-save' and envelope['version'] == 1
            and hashlib.sha256(envelope['body'].encode()).hexdigest() == envelope['sha256'], 'parent_ledger_checksum')
    ledger = json.loads(envelope['body'])
    parent = canonical_parent(fixture['parent'])
    require(durable.digest(parent) == PARENT_DIGEST, 'parent_digest_mismatch')
    require(ledger['format'] == 'pc-first-operation-settlements/1' and parent['id'] in ledger['consumed'], 'parent_not_consumed')
    require(canonical_parent(ledger['consumed'][parent['id']]) == parent, 'consumed_parent_mismatch')
    require(generated['status'] == reopened['status'] == 'PASS' and generated['checks_total'] == generated['checks_passed'] == 26
            and reopened['checks_total'] == reopened['checks_passed'] == 6 and generated['pid'] != reopened['pid'], 'parent_proof_failed')
    require(generated['details'] == fixture and fixture['ledger'] == ledger
            and canonical_parent(reopened['details']['parent']) == parent, 'parent_proof_mismatch')
    require(generated['details']['ledger_sha256'] == reopened['details']['ledger_sha256'] == PINS['parent-ledger.save'], 'parent_reopen_mismatch')
    terminal = [row for row in observed['events'] if row.get('kind') == 'operation_settled']
    require(len(terminal) == 1 and terminal[0]['fact'] == observed['summary']['settlement']
            == observed['projection']['operation']['settlement'] == fixture['terminal'], 'parent_terminal_mismatch')
    require(parent['kind'] == 'objective_success' and parent['reason'] == 'objective_conditions_met'
            and observed['summary']['tick'] == 5487 and observed['summary']['clock_ms'] == parent['clock_ms'], 'parent_ineligible')
    return parent, ledger


def worker(args):
    try:
        parent, _ledger = validate_parent(args.parent_dir)
        durable.PARENT = parent.copy()  # Bound once from trusted fixture data, never from the intent.
    except (ParentRejected, OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({'pid': os.getpid(), 'reply': {'error': 'invalid_parent_artifact', 'reason': str(error)}}))
        return
    reply = durable.apply(args.db, json.loads(args.intent), args.actor, args.prepared, args.crash)
    print(json.dumps({'pid': os.getpid(), 'reply': reply}))


class Integration(durable.Evaluation):
    def launch(self, db, intent, prepared, actor=durable.ACTOR, crash='', parent_dir=None):
        command = [sys.executable, '-B', __file__, '--worker', '--db', str(db), '--intent', json.dumps(intent),
                   '--prepared', str(prepared), '--actor', actor, '--crash', crash,
                   '--parent-dir', str(parent_dir or self.inputs)]
        return subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                                creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))

    def initialize(self, db, policy, prepared, ledger):
        durable.initialize(db, policy, prepared)
        # Keep the complete real ledger, including format and latest, in the new fixture DB.
        with closing(durable.connect(db)) as connection:
            connection.execute('UPDATE authority SET ledger=?', (json.dumps(ledger),))
        return ledger

    def state_is(self, db, generation, count, ledger):
        actual_generation, actual_ledger, rows = durable.inspect(db)
        return actual_generation == generation and len(rows) == count and actual_ledger == ledger

    def run(self):
        original, ledger = validate_parent(self.args.parent_dir)
        durable.PARENT = original.copy()  # One fixture configuration for the coordinator process.
        self.check('pinned real consumed parent has canonical approved digest', durable.digest(original) == PARENT_DIGEST)
        source_hashes = {name: durable.file_sha(self.args.parent_dir / name) for name in PINS}
        self.inputs = self.root / 'parent-inputs'
        self.inputs.mkdir()
        for name in PINS:
            shutil.copyfile(self.args.parent_dir / name, self.inputs / name)
        self.check('isolated input copy preserves all reviewed parent bytes', validate_parent(self.inputs) == (original, ledger))
        self.check('fresh process DTO fixture remains a strict numeric contract',
                   canonical_parent(dict(original, seed=208.0, clock_ms=548700.0)) == original)
        for name, value in [('seed', True), ('clock_ms', False), ('seed', 208.5), ('clock_ms', '548700')]:
            try:
                canonical_parent(dict(original, **{name: value}))
                rejected = False
            except ParentRejected:
                rejected = True
            self.check('reject invalid parent numeric representation ' + name + ':' + repr(value), rejected)
        self.check('reviewed child restore baseline bytes are pinned', durable.file_sha(self.args.baseline) == BASELINE_SHA)
        baseline = read(self.args.baseline)['snapshots']['c0']
        target = {key: baseline[key] for key in ('request', 'rules_digest', 'source_digest', 'effective_digest', 'state_digest')}
        target.update(schema='cross-counter-local-durable-target/1', public_activation=False)
        policy = {'version': 'cross-counter-local-durable-policy/1', 'eligible_kinds': ['objective_success'],
                  'eligible_reasons': ['objective_conditions_met'], 'target': target}
        policy_digest = durable.digest(policy)
        transition_id = durable.digest({'schema': 'cross-counter-local-transition/1', 'campaign': durable.CAMPAIGN,
                                        'parent_digest': PARENT_DIGEST, 'policy_digest': policy_digest})
        operation_id = durable.DEFINITION + '/' + transition_id
        prepared, proof = self.engine('prepare-real-parent-child', {'mode': 'prepare', 'operation_id': operation_id})
        details = proof['details']
        self.check('real child C0 matches reviewed baseline under actual-parent derived identity',
                   details['published'] is False and details['operation_id'] == operation_id
                   and all(details['packet'][key] == target[key] for key in
                           ('request', 'rules_digest', 'source_digest', 'effective_digest', 'state_digest')))
        intent = {'campaign_id': durable.CAMPAIGN, 'intent_id': 'actual-parent-confirm-1', 'generation': 9,
                  'parent_id': original['id'], 'parent_digest': PARENT_DIGEST, 'policy_digest': policy_digest,
                  'target_digest': durable.digest(target), 'c0_sha256': details['binding']['packet_sha256'], 'confirmed': True}
        durable.write(self.root / 'intent.json', intent)
        durable.write(self.root / 'policy.json', policy)
        durable.write(self.root / 'real-parent.json', {'synthetic': False, 'facts': original, 'ledger': ledger})
        db = self.root / 'actual-parent.sqlite'
        self.initialize(db, policy, prepared, ledger)
        self.check('authority initializes with the entire actual consumed ledger', self.state_is(db, 9, 0, ledger))
        bad_inputs = self.root / 'altered-parent-inputs'
        shutil.copytree(self.inputs, bad_inputs)
        with (bad_inputs / 'parent-fixture.json').open('ab') as changed:
            changed.write(b'\n')
        denied = self.collect(self.launch(db, intent, prepared, parent_dir=bad_inputs))
        self.check('worker rejects a substituted parent artifact before transition', denied.get('error') == 'invalid_parent_artifact')
        self.check('wrong actor fixture rejects a new actual-parent transition',
                   self.collect(self.launch(db, intent, prepared, actor='untrusted')) == {'error': 'forbidden'})
        self.check('changed actual parent digest cannot authorize a transition',
                   self.collect(self.launch(db, dict(intent, parent_digest='0' * 64), prepared)) == {'error': 'parent_mismatch'})
        self.check('rejections preserve actual ledger, generation and zero C0 rows', self.state_is(db, 9, 0, ledger))
        unconsumed = self.root / 'unconsumed-parent.sqlite'
        missing_ledger = dict(ledger, consumed={})
        self.initialize(unconsumed, policy, prepared, missing_ledger)
        self.check('latest alone cannot supply the consumed parent',
                   self.collect(self.launch(unconsumed, intent, prepared)) == {'error': 'parent_mismatch'}
                   and self.state_is(unconsumed, 9, 0, missing_ledger))
        self.collect(self.launch(db, intent, prepared, crash='after'), 72)
        self.check('response-loss commit binds one C0 with the actual parent and CAS generation', self.state_is(db, 10, 1, ledger))
        response = self.collect(self.launch(db, intent, prepared))
        self.check('restart recovers the exact actual-parent derived operation and C0',
                   response['operation_id'] == operation_id and response['transition_id'] == transition_id
                   and response['parent_id'] == original['id'] and response['c0_sha256'] == intent['c0_sha256'])
        self.check('historical retry does not require a now-missing preparation file',
                   self.collect(self.launch(db, intent, self.root / 'missing-preparation.json')) == response)
        self.check('historical actual-parent response still requires the fixture actor',
                   self.collect(self.launch(db, intent, prepared, actor='untrusted')) == {'error': 'forbidden'})
        record = durable.record(db)
        committed = durable.inspect(db)[2][0]
        self.check('stored C0 binary and binding are exactly the actual prepared bytes',
                   committed[1] == base64.b64decode(details['packet_b64'], validate=True)
                   and hashlib.sha256(committed[1]).hexdigest() == record['c0_sha256'] == record['binding']['packet_sha256'])
        # inspect/record have closed every SQLite connection before any Godot launch.
        db_sha = durable.file_sha(db)
        _, restored = self.engine('actual-parent-committed-restore', {'mode': 'restore', 'authority_committed': True, 'record': record})
        self.check('new Godot process validates and publishes the actual-parent committed C0',
                   restored['details']['published'] is True and restored['details']['operation_id'] == operation_id
                   and restored['details']['packet_sha256'] == intent['c0_sha256'] and restored['pid'] != proof['pid'])
        bad = json.loads(json.dumps(record))
        bad['binding']['packet_sha256'] = '0' * 64
        _, rejected = self.engine('actual-parent-bad-bind', {'mode': 'restore', 'authority_committed': True,
                                                           'record': bad, 'expect_rejection': True})
        self.check('bad bind preserves old live owner and the committed actual-parent DB',
                   rejected['details']['old_owner_unchanged'] is True and rejected['details']['published'] is False
                   and durable.file_sha(db) == db_sha and self.state_is(db, 10, 1, ledger))
        _, retried = self.engine('actual-parent-valid-retry', {'mode': 'restore', 'authority_committed': True, 'record': durable.record(db)})
        self.check('another engine PID retries the exact committed C0 after rejected publication',
                   retried['pid'] != restored['pid'] and retried['details'] == restored['details'])
        self.check('entire actual source ledger and all reviewed parent evidence remain byte-identical',
                   all(durable.file_sha(self.args.parent_dir / name) == value for name, value in source_hashes.items()))
        self.check('publication leaves the authority record and actual parent unchanged',
                   durable.file_sha(db) == db_sha and self.state_is(db, 10, 1, ledger))
        result = {'schema': 'cross-counter-real-parent-durable-proof/1', 'status': 'PASS',
                  'checks': self.checks, 'checks_passed': len(self.checks), 'checks_total': len(self.checks),
                  'workers': self.workers, 'engines': self.engines, 'parent': original, 'parent_digest': PARENT_DIGEST,
                  'operation_id': operation_id, 'c0_sha256': intent['c0_sha256'], 'rules_digest': target['rules_digest'],
                  'parent_input_pins': PINS, 'actual_parent_fixture_configured_once_per_process': True,
                  'synthetic_parent': False, 'real_child_engine_c0': True, 'single_pc': True,
                  'public_activation': False, 'real_service_authentication': False, 'active_owner_lease_tested': False,
                  'product_ui_tested': False, 'existing_user_saves_accessed': False,
                  'python': sys.version.split()[0], 'sqlite': sqlite3.sqlite_version}
        durable.write(self.root / 'result.json', result)
        print('CROSS_COUNTER_REAL_PARENT_DURABLE_RESULT PASS', len(self.checks), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--worker', action='store_true')
    parser.add_argument('--db', type=Path)
    parser.add_argument('--intent')
    parser.add_argument('--prepared', type=Path)
    parser.add_argument('--actor', default=durable.ACTOR)
    parser.add_argument('--crash', default='')
    parser.add_argument('--parent-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--engine', type=Path)
    parser.add_argument('--worktree', type=Path)
    parser.add_argument('--baseline', type=Path)
    args = parser.parse_args()
    worker(args) if args.worker else Integration(args).run()


if __name__ == '__main__':
    main()
