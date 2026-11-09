"""P02 evidence runner. Explicit attempt number, append-only output names."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
ENGINE = Path('C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    assert not path.exists(), str(path)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')


def freeze(attempt):
    target = OUT / f'attempt{attempt}-suite-inputs.json'
    assert not target.exists(), 'Attempt already exists; do not overwrite evidence'
    paths = list((ROOT / 'core/battle').rglob('*.gd'))
    paths += [ROOT / 'tests/autoresolve.gd', ROOT / 'tests/p02_headless_adapter.gd',
              ROOT / '.godot/global_script_class_cache.cfg', Path(__file__)]
    paths += list((ROOT / 'tests/fixtures/p02').glob('*.json'))
    paths += [ROOT / 'data/profiles/poc_corridor.json', ROOT / 'data/profiles/combat_m3.json']
    paths += list(ENGINE.parent.glob('*.exe'))
    rows = []
    for path in paths:
        relative = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
        rows.append(dict(path=str(relative), bytes=path.stat().st_size, sha256=sha(path)))
        if path.suffix == '.gd':
            copy = OUT / f'attempt{attempt}-suite-source' / relative
            copy.parent.mkdir(parents=True, exist_ok=True)
            copy.with_suffix('.gd.txt').write_bytes(path.read_bytes())
    write_json(target, dict(attempt=attempt, limit=6, inputs=rows))


def run(label, script, args=()):
    log = OUT / (label + '-captured.log')
    engine_log = OUT / (label + '-engine.log')
    assert not log.exists() and not engine_log.exists(), label
    command = [str(ENGINE), '--headless', '--path', str(ROOT), '--log-file',
               str(engine_log), '-s', str(script)]
    if args:
        command += ['--', *map(str, args)]
    with log.open('wb') as stream:
        process = subprocess.run(command, cwd=ROOT, stdout=stream,
                                 stderr=subprocess.STDOUT, timeout=300)
    text = log.read_text(encoding='utf-8')
    row = dict(label=label, command=command, actual_exit=process.returncode,
               script_errors=text.count('SCRIPT ERROR:'),
               errors=text.count('\nERROR:'), warnings=text.count('WARNING:'),
               log_sha256=sha(log), engine_log_sha256=sha(engine_log))
    write_json(OUT / (label + '-exit.json'), row)
    print(label, 'exit=', process.returncode, 'script_errors=', row['script_errors'],
          'errors=', row['errors'], flush=True)
    return row, text


def main(attempt):
    freeze(attempt)
    prefix = f'attempt{attempt}'
    source = ROOT / 'tests/p02_headless_adapter.gd'
    original = source.read_bytes()
    old = b'attempt1-observations.json'
    replacement = f'attempt{attempt}-observations.json'.encode()
    # Executable OUT-only copy. It has no global class_name and never gets imported.
    copy = OUT / (prefix + '-api-runner.gd')
    assert not copy.exists()
    copy.write_bytes(original.replace(old, replacement))
    inverse = copy.read_bytes().replace(replacement, old)
    assert inverse == original
    write_json(OUT / (prefix + '-out-only.json'), dict(source_sha256=sha(source),
               runner_sha256=sha(copy), inverse_sha256=hashlib.sha256(inverse).hexdigest()))
    api, _ = run(prefix + '-api', copy)
    if api['actual_exit'] or api['script_errors'] or api['errors']:
        print('API failed; no CLI/regression started', flush=True)
        return 1
    directory = OUT / (prefix + '-cli-inputs')
    directory.mkdir()
    poc = json.loads((ROOT / 'tests/fixtures/p02/poc.json').read_text(encoding='utf-8'))
    services = json.loads((ROOT / 'tests/fixtures/p02/services.json').read_text(encoding='utf-8'))
    poc_path = ROOT / 'tests/fixtures/p02/poc.json'
    service_path = ROOT / 'tests/fixtures/p02/services.json'
    malformed = directory / 'malformed.json'
    malformed.write_text('{', encoding='utf-8')
    scalar = directory / 'scalar.json'
    scalar.write_text('[]', encoding='utf-8')
    charge = directory / 'charge.json'
    charge_data = dict(poc, policy='charge30')
    write_json(charge, charge_data)
    stock = directory / 'stock.json'
    stock_data = dict(poc, profile=json.loads((ROOT / 'data/profiles/poc_corridor.json').read_text(encoding='utf-8')), initial_controls=[])
    write_json(stock, stock_data)
    sentinel = directory / 'sentinel.json'
    sentinel.write_bytes(b'preserve-existing-output\r\n')
    sentinel_before = sha(sentinel)
    default_out = directory / 'default-result.json'
    tests = [
        ('N01', ['--operation-input'], 'missing_option_value', '--operation-input'),
        ('N03', ['--operation-input', malformed, '--out', default_out], 'invalid_json', 'input'),
        ('N14', ['--operation-input', charge, '--out', default_out], 'unsupported_policy', 'policy'),
        ('N15', ['--operation-input', poc_path, '--profile', 'red_cliffs', '--out', default_out], 'conflicting_option', '--profile'),
        ('Z01', ['--operation-input', poc_path], 'missing_option', '--out'),
        ('Z02', ['--operation-input', '', '--out', default_out], 'missing_option_value', '--operation-input'),
        ('Z03', ['--operation-input', poc_path, '--bogus', '--out', default_out], 'unknown_option', '--bogus'),
        ('Z04', ['--operation-input', poc_path, '--out', default_out, '--out', default_out], 'duplicate_option', '--out'),
        ('Z05', ['--operation-input', directory / 'absent.json', '--out', default_out], 'input_read_failed', 'input'),
        ('Z06', ['--operation-input', scalar, '--out', default_out], 'invalid_container', '$'),
        ('Z07', ['--operation-input', stock, '--out', default_out], 'unsupported_reinforcement', 'profile.reinf'),
        ('Z08', ['--operation-input', poc_path, '--out', sentinel], 'output_exists', 'out'),
        ('Z09', ['--operation-input', poc_path, '--out', directory / 'absent-parent' / 'result.json'], 'output_parent_missing', 'out'),
        ('Z10', ['--operation-input', poc_path, '--out', directory / 'bad*.json'], 'output_open_failed', 'out'),
    ]
    inputs = list(directory.glob('*.json')) + [poc_path, service_path]
    before = {str(path): sha(path) for path in inputs}
    write_json(OUT / (prefix + '-cli-inputs.json'), before)
    rows = []
    for case, args, code, path in tests:
        row, text = run(prefix + '-' + case, 'tests/autoresolve.gd', args)
        lines = [line.removeprefix('OPERATION_REJECT ') for line in text.splitlines() if line.startswith('OPERATION_REJECT ')]
        error = json.loads(lines[-1]) if lines else {}
        row['expected_error'] = code
        row['expected_path'] = path
        row['observed'] = error
        row['pass'] = (row['actual_exit'] == 1 and row['script_errors'] == 0 and
                       error.get('error') == code and error.get('path') == path and
                       'PASS' not in text and sha(sentinel) == sentinel_before and not default_out.exists())
        rows.append(row)
    observations = json.loads((OUT / (prefix + '-observations.json')).read_text(encoding='utf-8'))
    for kind, path in [('poc', poc_path), ('services', service_path)]:
        output = directory / (kind + '-result.json')
        row, text = run(prefix + '-success-' + kind, 'tests/autoresolve.gd', ['--operation-input', path, '--out', output])
        result = json.loads(output.read_text(encoding='utf-8')) if output.exists() else {}
        expected = next(c['consumer_summary'] for c in observations['cases'] if c['seed'] == 0 and c['profile'] == kind and c['policy'] == 'attack5')
        row['pass'] = (row['actual_exit'] == 0 and row['script_errors'] == 0 and row['errors'] == 0 and
                       'OPERATION_HEADLESS_PASS ' in text and result.get('summary') == expected and
                       result.get('meta', {}).get('input_file_sha256') == sha(path))
        rows.append(row)
    baseline = OUT / (prefix + '-legacy-before.gd')
    baseline.write_bytes((OUT / 'autoresolve.gd.before.txt').read_bytes())
    assert sha(baseline) == sha(OUT / 'autoresolve.gd.before.txt')
    write_json(OUT / (prefix + '-legacy-source.json'), dict(original_sha256=sha(OUT / 'autoresolve.gd.before.txt'), execution_sha256=sha(baseline), inverse_sha256=sha(baseline), transformation='none; output supplied by CLI'))
    legacy_outputs = []
    for side, script in [('before', baseline), ('after', 'tests/autoresolve.gd')]:
        output = directory / ('legacy-' + side + '.json')
        row, text = run(prefix + '-legacy-' + side, script, ['--runs', '1', '--policies', 'none', '--out', output])
        row['pass'] = row['actual_exit'] == 0 and row['script_errors'] == 0 and row['errors'] == 0 and 'AUTORESOLVE_PASS' in text
        rows.append(row)
        legacy_outputs.append(json.loads(output.read_text(encoding='utf-8')) if output.exists() else None)
    legacy_equal = legacy_outputs[0] is not None and legacy_outputs[0] == legacy_outputs[1]
    preserved = all(sha(Path(path)) == digest for path, digest in before.items())
    write_json(OUT / (prefix + '-cli-results.json'), dict(rows=rows, negative_cases=14, success_cases=2, legacy_processes=2, legacy_exact_equal=legacy_equal, input_preserved=preserved, ok=all(row['pass'] for row in rows) and legacy_equal and preserved))
    if not all(row['pass'] for row in rows) or not legacy_equal or not preserved:
        print('CLI failed; regressions not started', flush=True)
        return 1
    regression = []
    original = (ROOT / 'tests/i01b_private_state.gd').read_bytes()
    old = b'res://tmp/i01b-p2c-resume-20261101/attempt5-observations.json'
    new = f'res://tmp/p02-first-integration-20261105/{prefix}-private-observations.json'.encode()
    copy = OUT / (prefix + '-private-regression.gd')
    copy.write_bytes(original.replace(old, new))
    assert copy.read_bytes().replace(new, old) == original
    write_json(OUT / (prefix + '-private-out-only.json'), dict(source_sha256=sha(ROOT / 'tests/i01b_private_state.gd'), runner_sha256=sha(copy), inverse_sha256=hashlib.sha256(copy.read_bytes().replace(new, old)).hexdigest()))
    for name, script in [('private', copy), ('core', 'tests/core_rules.gd')]:
        row, _ = run(prefix + '-regression-' + name, script)
        regression.append(row)
    write_json(OUT / (prefix + '-regressions.json'), regression)
    return 0 if all(row['actual_exit'] == 0 and row['script_errors'] == 0 for row in regression) else 1


if __name__ == '__main__':
    sys.exit(main(int(sys.argv[1])))
