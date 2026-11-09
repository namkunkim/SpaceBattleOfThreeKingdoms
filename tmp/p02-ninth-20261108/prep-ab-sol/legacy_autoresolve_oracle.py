"""Offline V5 row 20 legacy result comparator. Never launches a process."""
import argparse
import json
import re
from decimal import Decimal
from pathlib import Path

POLICIES = ('none', 'attack5', 'charge30')
MEASURES = ('t', 'lost', 'killed', 'reinf_t')
COUNTS = ('ally_alive', 'foe_alive', 'commands')
RUN_FIELDS = {'win', 'reason', 'fp', *MEASURES, *COUNTS}
SUMMARY_FIELDS = {'n', 'win_rate', 'reasons', *(f'mean_{k}' for k in MEASURES)}

def need(condition, where):
    if not condition:
        raise ValueError(where)

def unique(pairs):
    obj = {}
    for key, value in pairs:
        need(key not in obj, f'duplicate key {key}')
        obj[key] = value
    return obj

def constant(value):
    raise ValueError(f'non-finite token {value}')

def load(path):
    return json.loads(path.read_bytes(), object_pairs_hook=unique, parse_float=Decimal, parse_constant=constant)

def number(value):
    return type(value) is int or (type(value) is Decimal and value.is_finite())

def same(a, b, where='$'):
    need(type(a) is type(b), f'{where}: JSON type mismatch')
    if isinstance(a, dict):
        need(a.keys() == b.keys(), f'{where}: field mismatch')
        for k in a:
            same(a[k], b[k], f'{where}.{k}')
    elif isinstance(a, list):
        need(len(a) == len(b), f'{where}: list length mismatch')
        for i, (left, right) in enumerate(zip(a, b)):
            same(left, right, f'{where}[{i}]')
    else:
        need(a == b, f'{where}: value mismatch')

def validate(doc):
    need(type(doc) is dict and doc.keys() == {'meta','policies'}, 'legacy top-level schema')
    meta = doc['meta']
    need(type(meta) is dict and meta.keys() == {'hz','runs','max_s'}, 'legacy meta schema')
    for k, expected in [('hz',10),('runs',200),('max_s',1800)]:
        need(number(meta[k]) and meta[k] == expected, f'meta.{k}')
    pols = doc['policies']
    need(type(pols) is dict and pols.keys() == set(POLICIES), 'legacy policy set')
    for pol in POLICIES:
        body = pols[pol]
        need(type(body) is dict and body.keys() == {'runs','summary'}, f'{pol} payload')
        runs, summary = body['runs'], body['summary']
        need(type(runs) is list and len(runs) == 200, f'{pol} run count')
        reasons, wins = {}, 0
        for i, row in enumerate(runs):
            where = f'{pol}[{i}]'
            need(type(row) is dict and row.keys() == RUN_FIELDS, f'{where} fields')
            need(type(row['win']) is bool, f'{where} win type')
            reason = row['reason']
            need(type(reason) is str and bool(reason), f'{where} reason type')
            need(type(row['fp']) is str and re.fullmatch(r'[a-f0-9]{64}', row['fp']), f'{where} fingerprint')
            need(all(number(row[k]) for k in MEASURES), f'{where} measure type')
            need(all(number(row[k]) and row[k] >= 0 and row[k] == int(row[k]) for k in COUNTS), f'{where} count type')
            wins += row['win']
            reasons[reason] = reasons.get(reason, 0) + 1
        need(type(summary) is dict and summary.keys() == SUMMARY_FIELDS, f'{pol} summary fields')
        need(number(summary['n']) and summary['n'] == 200, f'{pol} summary count')
        need(number(summary['win_rate']) and summary['win_rate'] == Decimal(wins) / 200, f'{pol} win rate')
        reported = summary['reasons']
        need(type(reported) is dict and reported.keys() == reasons.keys(), f'{pol} reason summary fields')
        need(all(number(reported[k]) and reported[k] == v for k,v in reasons.items()), f'{pol} reason counts')
        need(all(number(summary[f'mean_{k}']) for k in MEASURES), f'{pol} mean type')

def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('before', type=Path)
    cli.add_argument('after', type=Path)
    args = cli.parse_args()
    left, right = load(args.before), load(args.after)
    validate(left)
    validate(right)
    same(left, right)
    print('legacy output equality: 3 policies, 600 ordered rows')

if __name__ == '__main__':
    main()
