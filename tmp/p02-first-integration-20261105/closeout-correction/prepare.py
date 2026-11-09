from pathlib import Path
import difflib, hashlib, json, subprocess
root = Path.cwd()
ev = root / 'tmp/p02-first-integration-20261105'
out = ev / 'closeout-correction'
doc = root / 'docs/battle-core/pc-campaign-design'
paths = [doc / n for n in ('P02-FIRST-HEADLESS-RESULT-20261107.md','P02-FIRST-HEADLESS-CHECKLIST-20261107.md','SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md','SESSION-REQUIREMENTS-CHECKLIST-20261031.md')] + [root / 'docs/battle-core/CHECKLIST-OPEN.md']
sha = lambda b: hashlib.sha256(b).hexdigest()
def write(name, payload):
    with (out / name).open('xb') as f:
        f.write(payload)
def js(name, payload):
    write(name, json.dumps(payload, indent=2, ensure_ascii=False).encode())
def gate(phase):
    r = subprocess.run(['git', 'diff', '--check'], capture_output=True)
    write(f'{phase}-full-diff-check.log', r.stdout + r.stderr)
    return r.returncode
before_exit = gate('before')
proof = []
for i, p in enumerate(paths):
    old = p.read_bytes()
    lines = old.decode('utf-8').splitlines(keepends=True)
    edits = {}
    for n, l in enumerate(lines):
        if i == 0:
            if n == 0: l = '# P02 첫 실제 headless opt-in — 구현·검사 결과\n'
            if n == 2: l = '2026-11-07 KST. 실제 CLI 소비자 연결 한 조각을 구현·검사했다. 비-Astra 독립 5b 및 마감 재심사 수용은 보류 중이다. 전체 P02/I01/I01b/A04~A06는 NOT_READY, 외부 save schema는 UNCLASSIFIED다. [전용 체크리스트](P02-FIRST-HEADLESS-CHECKLIST-20261107.md)와 [최신 인계](SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md)를 함께 따른다.\n'
            l = l.replace('**비차단 분류 편차**를 공개한 코드로 수용했다', '**분류 편차**를 확인했다')
        if i == 1:
            l = l.replace('이 조각만 [독립5b 제한 수용](../../../tmp/p02-first-integration-20261105/REVIEW-5B-ACCEPT-20261107.md).', '이번 조각의 비-Astra 독립 5b와 마감 재심사는 수용 보류 중이다.')
            if l.startswith('- [x] 5b '): l = '- [ ] 5b 비-Astra 독립 재심사 수용 대기. 구현 모델은 gpt-6.1-sol이다. 과거 gpt-6-astra 심사는 이력으로 보존한다.\n'
            l = l.replace('- [x] 6 결과', '- [ ] 6 결과')
        if i == 2:
            l = l.replace('·[독립5b](../../../tmp/p02-first-integration-20261105/REVIEW-5B-ACCEPT-20261107.md)', '')
            l = l.replace('실제 CLI opt-in 제한 수용이며', '실제 CLI opt-in 연결을 구현·검사했으며')
            l = l.replace('비차단 편차로 수용했다', '분류 편차가 관측됐다')
        if i == 3:
            l = l.replace('독립5b 제한 수용을 추가한다', '구현·검사 및 비-Astra 독립 재심사 보류 상태를 기록한다').replace('·독립5b 한정 수용(§9)', '·비-Astra 독립 재심사 수용 보류(§9)')
        if i == 4 and 'P02 첫 실제 headless opt-in 한정 연결' in l:
            l = l.replace('[x]', '[ ]', 1).replace('다른 모델5b 제한 수용', '비-Astra 독립 5b 재심사 수용 보류').replace(' · [독립5b](../../tmp/p02-first-integration-20261105/REVIEW-5B-ACCEPT-20261107.md). 최종 감사/압축과 [독립 마감 판정](../../tmp/p02-first-integration-20261105/REVIEW-CLOSEOUT-20261107.md)은 전용 증거를 따른다.', '. 정정 감사와 압축 검증은 결과 문서를 따른다.').rstrip() + '\n'
        if i < 4:
            import re
            l = re.sub(r'\[독립5b 제한 수용\]\([^)]+REVIEW-5B-ACCEPT-20261107.md\)', '비-Astra 독립 5b 재심사 수용 보류', l)
            if 'REVIEW-CLOSEOUT-20261107.md' in l:
                l = re.sub(r'독립 마감 판정은 \[별도 closeout\].*?대체하지 않는다\.', '비-Astra 독립 마감 판정은 보류 중이다.', l)
                l = re.sub(r'독립 closeout는 이 문서의 자체 수용 항목으로 체크하지 않고 \[최종 판정 파일\]\([^)]+\)을 따른다\.', '비-Astra 독립 마감 판정은 보류 중이다.', l)
                l = re.sub(r'독립 마감 상태는 \[closeout 판정\]\([^)]+\)이 정본이다\.', '비-Astra 독립 5b와 마감 재심사는 수용 보류 중이다.', l)
                l = re.sub(r'\[독립 closeout 판정\]\([^)]+\)은 압축 후 별도 확인이며', '비-Astra 독립 마감 판정은 보류 중이며', l)
            l = l.replace('/final-delivery-audit.json', '/closeout-correction/audit.json').replace('/record-manifest.json', '/closeout-correction/manifest.json').replace('/archive-verification.json', '/closeout-correction/archive-verification.json').replace('/p02-first-headless-delivery-20261107.zip', '/p02-first-headless-delivery-20261107-correction.zip')
            l = l.replace('전체 git diff --check는 보존한 기존 상위 P2c행 CRLF/trailing로 actual exit2이며 전체 gate PASS가 아니다.', '정정 전 전체 git diff --check는 기존 P2c 33행과 P02 35행의 trailing whitespace를 보고했다. P02 35행을 정정한 뒤 기존 P2c 33행 진단이 남아 전체 게이트는 미통과다. 실행별 종료 코드와 원문은 정정 감사에 기록했다.')
            l = l.replace('전체 diff-check는 기존 P2c 상위행으로 actual exit2이며 새 소유 코드공백0과 분리한다.', '정정 전 전체 diff-check는 P2c 33행과 P02 35행을 진단했다. P02 35행만 정정했고 기존 P2c 33행은 전체 게이트 미통과로 남아 있다.')
            l = l.replace('전체 diff-check exit2 해소', '전체 diff-check의 기존 P2c 33행 해소').replace('전체 diff-check exit2를 유지한다', '전체 diff-check의 기존 P2c 33행 미통과를 기록한다')
        if l != lines[n]: edits[n] = l
    if i == 0:
        edits[2] = edits[2].rstrip() + ' 과거 [gpt-6-astra 검토](../../../tmp/p02-first-integration-20261105/REVIEW-5B-ACCEPT-20261107.md)는 이력으로 보존한다.\n'
    if i == 4: assert set(edits) == {34}
    new = ''.join(edits.get(n, l) for n, l in enumerate(lines)).encode()
    write(p.name + '.before.txt', old)
    write(p.name + '.diff', ''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=str(p.relative_to(root)),tofile=str(p.relative_to(root)))).encode())
    assert p.read_bytes() == old
    p.write_bytes(new)
    reconstructed = new.decode().splitlines(keepends=True)
    for n in edits: reconstructed[n] = lines[n]
    assert ''.join(reconstructed).encode() == old
    proof.append(dict(path=p.relative_to(root).as_posix(), before_sha256=sha(old), after_sha256=sha(new), inverse_sha256=sha(old), lines=[n+1 for n in edits]))
after_exit = gate('after')
js('document-proof.json', dict(before_exit=before_exit, after_exit=after_exit, documents=proof))
