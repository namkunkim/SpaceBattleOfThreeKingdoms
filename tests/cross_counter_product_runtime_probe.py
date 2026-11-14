"""Run approved product runtime acceptance on two fresh local Godot PIDs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--worktree', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--packaged', action='store_true', help='run the acceptance main scene from an isolated exported probe package')
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env['SBTK_CC_RESULT_DIR'] = str(out)
    env['SBTK_CC_TEST_ROOT'] = str(out / 'profiles')
    runs = []
    for phase in ['generate', 'reopen']:
        profile = out / 'profiles' / phase
        for key in ['APPDATA', 'LOCALAPPDATA']:
            folder = profile / key
            folder.mkdir(parents=True)
            env[key] = str(folder)
        command = [str(args.engine), '--headless', '--path', str(args.worktree), '--script',
                   'tests/cross_counter_product_runtime_probe.gd']
        if args.packaged:
            command = [str(args.engine), '--headless']
        if phase == 'reopen':
            command += ['--', '--reopen']
        started = time.time()
        with (out / (phase + '.stdout')).open('wb') as stdout, (out / (phase + '.stderr')).open('wb') as stderr:
            process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
            code = process.wait(timeout=180)
        run = {'phase': phase, 'launcher_pid': process.pid, 'exit_code': code, 'started': started,
               'ended': time.time(), 'command': command}
        runs.append(run)
        (out / 'run.json').write_text(json.dumps(runs, indent=2), encoding='utf-8')
        print(json.dumps(run), flush=True)
        if code:
            raise SystemExit(code)
        result = json.loads((out / (phase + '-result.json')).read_text(encoding='utf-8'))
        assert result['status'] == 'PASS' and type(result['pid']) is int and result['pid'] > 0
        run['engine_pid'] = result['pid']
        (out / 'run.json').write_text(json.dumps(runs, indent=2), encoding='utf-8')
        assert not (out / (phase + '.stderr')).read_bytes()
    assert runs[0]['engine_pid'] != runs[1]['engine_pid']
    files = []
    for path in sorted(out.rglob('*')):
        if path.is_file():
            files.append({'path': path.relative_to(out).as_posix(), 'bytes': path.stat().st_size,
                          'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    (out / 'SHA256.json').write_text(json.dumps({'files': files}, indent=2), encoding='utf-8')
    print('CROSS_COUNTER_PRODUCT_TWO_PID_PASS', flush=True)


if __name__ == '__main__':
    main()
