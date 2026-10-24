"""Audit every GDScript literal and all player-facing JSON fields.

Run: python tools/audit-localization.py --check
Developer-only rule notes and identifiers are not presentation fields.
"""
import argparse
import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HANGUL = re.compile(r'[가-힣]')
TOKEN = re.compile(r'#[^\n]*|"""[\s\S]*?"""|\x27\x27\x27[\s\S]*?\x27\x27\x27|"(?:\\.|[^"\\])*"|\x27(?:\\.|[^\x27\\])*\x27')
FORMAT = re.compile(r'%[-+0-9.]*([dsf])')
SHOWN = {
    'name', 'role', 'label', 'title', 'text', 'claimed', 'estimate', 'effect',
    'description', 'desc', 'directive', 'reason', 'target_label', 'flavor',
    'line', 'speaker', 'why', 'display_name', 'grade', 'holder', 'kind', 'era',
    'date_label', 'location_label', 'ship_class', 'width', 'requires_trait',
    'disposition', 'cao_exit', 'alliance_exit',
}
SHOWN_ARRAYS = {'traits', 'weapon_specs', 'result_grades'}
# Exact exceptions: language autonyms stay recognizable, and these are replacement keys.
SOURCE_EXCEPTIONS = {
    ('hud/ui_kit/game_locale.gd', '한국어'),
    ('scripts/world/battle_outcome.gd', '{조조_상태}'),
    ('scripts/world/battle_outcome.gd', '{손실_적}'),
    ('scripts/world/battle_outcome.gd', '{시각}'),
}


def literals(source):
    for match in TOKEN.finditer(source):
        if match[0].startswith('#'):
            continue
        try:
            token = match[0]
            # GDScript permits physical newlines in ordinary quoted strings.
            if not token.startswith(('"""', "'''")):
                token = token.replace('\r', '\\r').replace('\n', '\\n')
            value = ast.literal_eval(token)
        except (ValueError, SyntaxError):
            continue
        if isinstance(value, str) and HANGUL.search(value):
            yield value, source.count('\n', 0, match.start()) + 1


def inventory():
    found = {}
    def record(value, location):
        if isinstance(value, str) and HANGUL.search(value):
            found.setdefault(value, []).append(location)
    for folder in ('core', 'hud', 'input', 'scripts', 'view', 'scenes'):
        for path in sorted((ROOT / folder).rglob('*')):
            if path.suffix not in ('.gd', '.tscn'):
                continue
            relative = path.relative_to(ROOT).as_posix()
            for value, line in literals(path.read_text(encoding='utf-8-sig')):
                if (relative, value) not in SOURCE_EXCEPTIONS:
                    record(value, f'{relative}:{line}')
    def walk(value, path, trail=''):
        if isinstance(value, dict):
            for key, child in value.items():
                location = f'{path}:{trail}/{key}'
                if key in SHOWN or (key == 'note' and '/difficulty_profiles/' in trail):
                    record(child, location)
                if key in SHOWN_ARRAYS and isinstance(child, list):
                    for index, entry in enumerate(child):
                        record(entry, f'{location}/{index}')
                walk(child, path, trail + '/' + key)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                walk(child, path, trail + '/' + str(index))
    for path in sorted((ROOT / 'data').rglob('*.json')):
        if 'i18n' not in path.parts:
            walk(json.loads(path.read_text(encoding='utf-8-sig')), path.relative_to(ROOT).as_posix())
    return found


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='fail on missing or invalid translations')
    parser.add_argument('--report', type=Path, help='write a full inventory and coverage report')
    args = parser.parse_args()
    catalog = json.loads((ROOT / 'data/i18n/messages.json').read_text(encoding='utf-8'))
    sources = inventory()
    missing = {key: locations for key, locations in sources.items() if key not in catalog}
    invalid = []
    for key, values in catalog.items():
        if not isinstance(values, list) or len(values) != 3:
            invalid.append({'source': key, 'reason': 'expected en/zh_CN/ja translations'})
            continue
        for locale, text in zip(('en', 'zh_CN', 'ja'), values):
            if not isinstance(text, str) or not text.strip():
                invalid.append({'source': key, 'locale': locale, 'reason': 'empty translation'})
            elif HANGUL.search(re.sub(r'\{[^{}]*\}', '', text)):
                invalid.append({'source': key, 'locale': locale, 'reason': 'untranslated Hangul'})
            elif FORMAT.findall(key) != FORMAT.findall(text):
                invalid.append({'source': key, 'locale': locale, 'reason': 'format placeholder mismatch'})
    report = {'catalog_messages': len(catalog), 'source_messages': len(sources),
              'source_occurrences': sum(map(len, sources.values())),
              'missing_count': len(missing), 'invalid_count': len(invalid),
              'missing': missing, 'invalid': invalid, 'sources': sources}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f"LOCALIZATION COVERAGE: {len(sources)} messages / {report['source_occurrences']} locations; "
          f"missing={len(missing)}, invalid={len(invalid)}; catalog={len(catalog)}")
    if missing:
        print(json.dumps(missing, ensure_ascii=False, indent=2))
    if invalid:
        print(json.dumps(invalid, ensure_ascii=False, indent=2))
    return 1 if args.check and (missing or invalid) else 0

if __name__ == '__main__':
    raise SystemExit(main())
