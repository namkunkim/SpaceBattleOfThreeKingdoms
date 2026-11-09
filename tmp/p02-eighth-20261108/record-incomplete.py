from pathlib import Path
import difflib, hashlib, json, re
p = Path("tmp/p02-eighth-20261108")
doc = Path("docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md")
before = doc.read_bytes()
line = b"\r\n" if b"\r\n## " in before else b"\n"
anchor = "## 남은 인수".encode()
assert before.count(anchor) == 1
insert = """## 미완료 — 두 제품 소비자의 공통 native 초기화 후보

- [ ] 격리 후보만 준비했다. 원본 제품 코드는 미적용이며 제품 operation·실제 UI 인수는 남아 있다. K1·K2는 비정본이다. K3는 일부 native 대조를 통과했고 K4는 WorldMap 정상 완료·취소를 viewport 입력으로 확인했다. 별도 오류 뒤 재시도는 175초 제한 뒤 join 단언이 실패했다. K4 GUI exit 81, K5 마우스 이벤트 주체 미확인으로 실제 OS 입력 근거는 미충족이다. PID·HWND·전경 확인 전 추가 OS 입력을 보류했다. K6은 미실행이고 계획 21행과 독립 5-b 수용은 미완료다. [중단 인계](../../../tmp/p02-eighth-20261108/SESSION-HANDOFF-INCOMPLETE.md) · [실행 근거](../../../tmp/p02-eighth-20261108/IMPLEMENTATION-EVIDENCE.md) · [격리 후보 패치](../../../tmp/p02-eighth-20261108/candidate-product.patch)

""".encode().replace(b"\n", line)
after = before.replace(anchor, insert + anchor, 1)
handoff = p/"SESSION-HANDOFF-INCOMPLETE.md"
for file, data in [(doc, insert.decode()), (handoff, handoff.read_text(encoding="utf-8-sig"))]:
    for link in re.findall(r"\]\(([^)]+)\)", data):
        assert (file.parent/link).is_file(), link
backup = p/"P02-PROGRESS-CHECKLIST.before.md"
diff = p/"P02-PROGRESS-CHECKLIST.diff"
assert not backup.exists() and not diff.exists()
backup.write_bytes(before)
diff.write_bytes(b"".join(difflib.diff_bytes(difflib.unified_diff, before.splitlines(keepends=True), after.splitlines(keepends=True), fromfile=b"before/P02-PROGRESS-CHECKLIST.md", tofile=b"after/P02-PROGRESS-CHECKLIST.md")))
assert doc.read_bytes()==before
doc.write_bytes(after)
assert doc.read_bytes().replace(insert,b"",1)==before
audit = {str(f): hashlib.sha256(f.read_bytes()).hexdigest() for f in (backup,diff,doc,handoff,p/"candidate-product.patch")}
(p/"incomplete-handoff-sha256.json").write_text(json.dumps(audit,indent=2), encoding="utf-8")
print(json.dumps(audit,indent=2))
