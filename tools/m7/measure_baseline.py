"""Checkpointed O3c baseline; uses the existing Godot simulation unchanged."""
import argparse
import concurrent.futures
import ctypes
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import time


def write_json(path, value):
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    temp.replace(path)


def summary(rows):
    n = len(rows)
    wins = sum(r['win'] for r in rows)
    p = wins / n
    z = 1.959963984540054
    center = (p + z*z/(2*n))/(1+z*z/n)
    half = z*((p*(1-p)/n+z*z/(4*n*n))**0.5)/(1+z*z/n)
    reasons = {}
    for row in rows:
        reasons[row['reason']] = reasons.get(row['reason'], 0) + 1
    ts = sorted(r['t'] for r in rows)
    ratios = [r['cost0'][1]/r['cost0'][0] for r in rows]
    return {'n': n, 'wins': wins, 'alliance_win_rate': p,
            'wilson_95': [max(0, center-half), min(1, center+half)],
            'median_seconds': statistics.median(ts), 'mean_seconds': statistics.mean(ts),
            'p10_seconds': ts[int((n-1)*.1)], 'p90_seconds': ts[int((n-1)*.9)],
            'reasons': reasons, 'time_limit_rate': reasons.get('time_limit', 0)/n,
            'foe_win_rate': sum(v for k, v in reasons.items() if k in ('alliance_morale_collapse', 'liu_flagship_lost', 'liu_cost_loss', 'alliance_cost_loss', 'liu_eliminated'))/n,
            'ally_cost_loss_percent': statistics.mean(r['ally_cost_loss_bp'] for r in rows)/100,
            'foe_cost_loss_percent': statistics.mean(r['foe_cost_loss_bp'] for r in rows)/100,
            'foe_cost_ratio_mean': statistics.mean(ratios),
            'first_hit_seconds_mean': statistics.mean(r['first_hit_t'] for r in rows)}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot', default=r'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe')
    ap.add_argument('--output', required=True)
    ap.add_argument('--runs', type=int, default=1000)
    ap.add_argument('--workers', type=int, default=8)
    ap.add_argument('--chunk', type=int, default=10)
    args = ap.parse_args()
    if min(args.runs, args.workers, args.chunk) < 1:
        ap.error('runs, workers and chunk must be positive')
    root = Path(__file__).resolve().parents[2]
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=True)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
    subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--', 'core', 'data', 'tests/autoresolve.gd'], cwd=root, check=True, stdout=subprocess.DEVNULL)
    settings = {'revision': revision, 'runs_per_difficulty': args.runs,
                'difficulties': ['입문', '표준'], 'seeds': [0, args.runs-1],
                'policy': 'none', 'organization': 'auto', 'skills': True,
                'player_counter_launch': False, 'enemy_counter_launch': True,
                'workers': args.workers, 'chunk': args.chunk, 'godot': args.godot}
    manifest = out / 'manifest.json'
    if manifest.exists() and json.loads(manifest.read_text(encoding='utf-8')) != settings:
        raise RuntimeError('Existing output belongs to different settings/revision')
    write_json(manifest, settings)
    started = time.time()
    totals = {d: 0 for d in settings['difficulties']}

    def run_chunk(diff, start):
        count = min(args.chunk, args.runs-start)
        path = out / f'{diff}_{start:04d}.json'
        if not path.exists():
            cmd = [args.godot, '--headless', '--path', str(root), '--log-file', str(out/f'{diff}_{start:04d}.engine.log'),
                   '--script', 'tests/autoresolve.gd', '--', '--profile', 'red_cliffs', '--difficulty', diff,
                   '--policies', 'none', '--org', 'auto', '--rows', '1', '--from', str(start),
                   '--runs', str(count), '--out', str(path)]
            result = subprocess.run(cmd, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    text=True, encoding='utf-8', errors='replace')
            (out/f'{diff}_{start:04d}.stdout.log').write_text(result.stdout, encoding='utf-8')
            if result.returncode or 'AUTORESOLVE_RC_DONE' not in result.stdout or 'SCRIPT ERROR' in result.stdout:
                raise RuntimeError(f'{diff} {start}: simulation failed; inspect stdout.log')
        data = json.loads(path.read_text(encoding='utf-8'))
        rows = data['policies']['none']['runs']
        if data['meta']['difficulty'] != diff or [r['seed'] for r in rows] != list(range(start, start+count)):
            raise RuntimeError(f'{path}: wrong difficulty, missing or duplicate seeds')
        if any(r['reason'] == 'timeout' or len(r['fp']) != 64 or r['ally_cost_loss_bp'] < 0 for r in rows):
            raise RuntimeError(f'{path}: incomplete simulation')
        return diff, rows, path

    # Hold system sleep only during this process; display may still sleep.
    if os.name == 'nt':
        ctypes.windll.kernel32.SetThreadExecutionState(0x80000001)
    try:
        all_rows = {d: [] for d in settings['difficulties']}
        hashes = {}
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            jobs = [pool.submit(run_chunk, d, start)
                    for start in range(0, args.runs, args.chunk) for d in settings['difficulties']]
            for job in concurrent.futures.as_completed(jobs):
                diff, rows, path = job.result()
                all_rows[diff].extend(rows)
                totals[diff] += len(rows)
                hashes[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
                write_json(out/'progress.json', {'completed': totals, 'elapsed_seconds': round(time.time()-started), 'revision': revision})
                print(json.dumps({'completed': totals, 'elapsed_seconds': round(time.time()-started)}, ensure_ascii=False), flush=True)
        if subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip() != revision:
            raise RuntimeError('Measurement checkout revision changed while running')
        subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--', 'core', 'data', 'tests/autoresolve.gd'], cwd=root, check=True, stdout=subprocess.DEVNULL)
        report = {'meta': settings, 'elapsed_seconds': round(time.time()-started), 'difficulties': {}}
        for diff, rows in all_rows.items():
            rows.sort(key=lambda r: r['seed'])
            if [r['seed'] for r in rows] != list(range(args.runs)):
                raise RuntimeError('Final seed coverage is not exact')
            report['difficulties'][diff] = summary(rows)
        write_json(out/'sha256.json', hashes)
        write_json(out/'summary.json', report)
        print('O3C_BASELINE_COMPLETE '+str(out/'summary.json'), flush=True)
    finally:
        if os.name == 'nt':
            ctypes.windll.kernel32.SetThreadExecutionState(0x80000000)


if __name__ == '__main__':
    main()
