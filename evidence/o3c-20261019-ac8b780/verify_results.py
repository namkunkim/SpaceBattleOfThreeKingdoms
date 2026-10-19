"""Verify the archived O3c rows and independently aggregate the published summary."""
import collections
import hashlib
import json
import math
from pathlib import Path
import re
import statistics as st
import zipfile

ROOT = Path(__file__).resolve().parent


def wilson(wins, n):
    z = 1.959963984540054
    p = wins / n
    den = 1 + z*z/n
    center = (p + z*z/(2*n)) / den
    half = z / den * math.sqrt(p*(1-p)/n + z*z/(4*n*n))
    return [max(0, center-half), min(1, center+half)]


def verify():
    manifest = json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
    published = json.loads((ROOT/'summary.json').read_text(encoding='utf-8'))
    hashes = json.loads((ROOT/'sha256.json').read_text(encoding='utf-8'))
    assert manifest['revision'] == 'ac8b780447c4ab156612b89ce1e30c0b04326a2e'
    assert published['meta'] == manifest
    assert manifest['runs_per_difficulty'] == 1000 and manifest['seeds'] == [0, 999]
    assert manifest['policy'] == 'none' and manifest['organization'] == 'auto' and manifest['skills']
    assert not manifest['player_counter_launch'] and manifest['enemy_counter_launch']
    result = {'revision': manifest['revision'], 'verified_files': len(hashes), 'difficulties': {}}
    defeat = {'alliance_morale_collapse', 'liu_flagship_lost', 'liu_cost_loss', 'alliance_cost_loss', 'liu_eliminated'}
    victory = {'cao_morale_collapse', 'cao_flagship_lost', 'cao_cost_loss', 'cao_eliminated', 'cao_escaped', 'alliance_escaped'}
    with zipfile.ZipFile(ROOT/'raw-results.zip') as archive:
        names = archive.namelist()
        assert len(names) == len(set(names)) == len(hashes) == 400
        assert set(names) == set(hashes)
        rows_by_diff = collections.defaultdict(list)
        for name in names:
            raw = archive.read(name)
            assert hashlib.sha256(raw).hexdigest() == hashes[name]
            match = re.fullmatch(r'(입문|표준)_(\d{4})\.json', name)
            assert match, name
            diff, start = match[1], int(match[2])
            data = json.loads(raw)
            assert data['meta']['difficulty'] == diff and data['meta']['org'] == 'auto'
            rows = data['policies']['none']['runs']
            assert [r['seed'] for r in rows] == list(range(start, start+5))
            rows_by_diff[diff].extend(rows)
        assert set(rows_by_diff) == {'입문', '표준'}
        for diff, rows in rows_by_diff.items():
            rows.sort(key=lambda r: r['seed'])
            assert [r['seed'] for r in rows] == list(range(1000))
            for r in rows:
                assert re.fullmatch('[0-9a-f]{64}', r['fp'])
                assert r['reason'] in defeat | victory | {'time_limit', 'simultaneous'}
                assert r['win'] == (r['reason'] in victory)
                assert 0 < r['t'] <= 1800 and 0 <= r['ally_cost_loss_bp'] <= 10000 and 0 <= r['foe_cost_loss_bp'] <= 10000
                assert r['cost0'] == [4022, 5912 if diff == '입문' else 6395]
            n = len(rows)
            wins = sum(r['win'] for r in rows)
            foe_wins = sum(r['reason'] in defeat for r in rows)
            reasons = dict(collections.Counter(r['reason'] for r in rows))
            ts = sorted(r['t'] for r in rows)
            expected = {'n': n, 'wins': wins, 'alliance_win_rate': wins/n, 'wilson_95': wilson(wins, n),
                        'median_seconds': st.median(ts), 'mean_seconds': st.mean(ts), 'p10_seconds': ts[99], 'p90_seconds': ts[899],
                        'reasons': reasons, 'time_limit_rate': reasons.get('time_limit', 0)/n, 'foe_win_rate': foe_wins/n,
                        'ally_cost_loss_percent': st.mean(r['ally_cost_loss_bp'] for r in rows)/100,
                        'foe_cost_loss_percent': st.mean(r['foe_cost_loss_bp'] for r in rows)/100,
                        'foe_cost_ratio_mean': st.mean(r['cost0'][1]/r['cost0'][0] for r in rows),
                        'first_hit_seconds_mean': st.mean(r['first_hit_t'] for r in rows)}
            actual = published['difficulties'][diff]
            assert set(actual) == set(expected)
            for key, value in expected.items():
                if isinstance(value, float):
                    assert math.isclose(actual[key], value, abs_tol=1e-10), (diff, key)
                elif isinstance(value, list):
                    assert all(math.isclose(a, b, abs_tol=1e-10) for a, b in zip(actual[key], value)), (diff, key)
                else:
                    assert actual[key] == value, (diff, key)
            chains = [r['m9']['chain'] for r in rows]
            ignited = [r for r in rows if r['m9']['chain']['ignite_t'] >= 0]
            skills = collections.Counter()
            for r in rows:
                skills.update(r['m9']['skills'])
            extra = {'foe_wins': foe_wins, 'foe_wilson_95': wilson(foe_wins, n),
                     'chain_letter_games': sum(c['letter_t'] >= 0 for c in chains),
                     'chain_ignited_games': len(ignited), 'chain_ignited_alliance_wins': sum(r['win'] for r in ignited),
                     'chain_detected_games': sum(c['detected'] > 0 for c in chains),
                     'wind_start_seconds_mean': st.mean(c['win_start_s'] for c in chains if c['win_start_s'] >= 0),
                     'skills_total': sum(skills.values()), 'skills_per_game': sum(skills.values())/n,
                     'skills_by_id': dict(sorted(skills.items())),
                     'assault_totals': {k: [sum(r['m9']['assault'][k][i] for r in rows) for i in range(2)] for k in rows[0]['m9']['assault']}}
            result['difficulties'][diff] = extra
    (ROOT/'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False, indent=2))
    print('O3C_ARCHIVE_VERIFIED: 400 hashes, 2000 unique difficulty/seed pairs, summary matched')


if __name__ == '__main__':
    verify()
