from pathlib import Path
from datetime import datetime, UTC
import hashlib, json, shutil, subprocess, zipfile
from freeze import ROOT, BASE, git, read, sha

stem = "P02-WORLD-RETURN-NOTICE"
day = "20261109"
docs = ROOT / "docs/battle-core/pc-campaign-design"
progress = docs / "P02-PROGRESS-CHECKLIST.md"
manifest = read(BASE / "EXECUTION-REVIEW-ONLY.json")
apply = read(BASE / "APPLY-RESULT.json")
assert sha(BASE / "APPLY-RESULT.json") == "d805e904deec414577c61421c9e80a8fb3beae0b1e23caa1f313c46091753566"
assert git("rev-parse", "HEAD") == apply["head"]
index = ROOT / git("rev-parse", "--git-path", "index")
assert sha(index) == apply["index_sha256"] and not git("diff", "--cached", "--name-only")
for name, old in manifest["source_map"].items():
    assert sha(ROOT / name) == apply["after"].get(name, old), name
for row in manifest["baseline"]["files"]:
    assert sha(ROOT / row["path"]) == apply["after"].get(row["path"], row["sha256"]), row["path"]

raw = BASE / "attempt-01"
artifact = {p for p in BASE.iterdir() if p.is_file() and p.name != Path(__file__).name}
artifact.add(raw / "results.json")
for cmd in manifest["commands"]:
    lane = Path(cmd["command_file"]).parent
    for name in ("command.json", "engine.log", "engine.os.tsv", "supervisor.stdout", "supervisor.stderr"):
        artifact.add(lane / name)
    artifact.update(lane / (name + ".png") for name in cmd.get("captures", []))
samples = set(artifact)
samples.update(p for p in (ROOT / "tmp").rglob("*.zip") if "p02" in p.name.lower())
samples.update(p for p in docs.glob("*.html"))
samples.update(ROOT / name for name in manifest["patched"])
samples.update(ROOT / row["path"] for row in manifest["baseline"]["files"] if ROOT / row["path"] != progress)
def snapshots():
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(samples)}

pre = snapshots()
disk_before = shutil.disk_usage(BASE).free
assert disk_before >= 2_500_000_000
now = datetime.now(UTC).isoformat()
files = {
    f"{stem}-RESULT-{day}.md": """# P02 천하 복귀 실패 안내 결과

일시정지·결과·최초 준비 실패의 천하 복귀가 즉시 거절되면 ‘천하로 돌아가지 못했습니다. 다시 눌러 주세요.’가 표시된다. 같은 버튼으로 다시 요청할 수 있다. WorldLink의 기존 rollback을 유지하고 실제 로더 Error를 전장과 UI에 전달한다. 네 대상은 적용 후 독립 검토에서 수용됐다.

격리 attempt-01의 28개 명령과 단언 728개가 통과했다. 로더 오류 48줄, Error 19 경고 24줄, 준비 fixture 오류 8줄은 예정 분모다. 프로그램 버튼 신호를 사용했으며 WorldLink fixture의 관측 배열은 제품 코드에서 제외했다. 결과는 강제 종료 fixture로 유도했다.

독립 검토자가 1600×900 앱 viewport PNG 18개에서 경고 가독성과 겹침을 확인했다. 최초 준비 화면의 42px 예약 슬롯으로 기준선 대비 버튼이 25px 아래로 이동했다. 후보의 반복 거절 동안 버튼 위치와 초점은 유지됐다. 다른 DPI·해상도, OS 입력, 자연 종료, 제품 operation은 미검증이다. 제품 원본 적용 뒤 Godot은 재실행하지 않았다.

[격리 결과](../../../tmp/p02-return-notice-20261109/ATTEMPT-01-RESULT.md) · [독립 5-b](../../../tmp/p02-return-notice-20261109/REVIEW-5B-INDEPENDENT.md) · [적용 후 독립 심사](../../../tmp/p02-return-notice-20261109/REVIEW-POST-APPLY-INDEPENDENT.md)
""",
    f"{stem}-CHECKLIST-{day}.md": """# P02 천하 복귀 실패 안내 체크리스트

- [x] 실제 즉시 Error와 기존 Brief/Outcome rollback.
- [x] 세 화면에서 첫째·둘째 거절 안내, 동일 버튼 재시도, 성공 시 기존 결과 처리.
- [x] 정상 첫 클릭·standalone 세 흐름·returning 설정과 비대상 원본 보존.
- [x] 격리 28개 명령·728개 단언 및 18개 1600×900 앱 viewport PNG.
- [x] 네 파일의 후보 바이트 일치, 역재구성, scoped diff 검사 및 적용 후 독립 확인.
- [ ] 전달 ZIP 독립 마감.
- [ ] 다른 해상도·DPI, 물리 OS 입력, 자연 전투 종료와 제품 operation은 이번 검증 밖이다. PC0 2/2 소진 및 별도 여덟째 K6 미실행을 유지한다.
""",
    f"SESSION-HANDOFF-{stem}-{day}.md": """# P02 천하 복귀 실패 안내 인계

제품은 적용 후 독립 수용 상태다. 적용 범위는 WorldLink, FleetBattle3D, command_deck, deck_screens 네 파일의 승인 hunk다. P03 공유 파일의 적용 전 SHA와 소유 상태를 확인했다. 소유 상태 조회와 보호 표본은 해당 시점의 관측이다.

전달 검토에서는 ZIP SHA, 구성원 SHA, 진행 체크리스트 역재구성, 로그·PNG 원본 및 감사 기록을 대조한다. ZIP에는 원시 검증 증거와 실행 명세를 넣고 약 670 MB 격리 프로젝트와 Godot 캐시는 제외했다. 기존 ZIP과 HTML, 원본·과거 캐시는 이 마감에서 변경하지 않았다. 독립 마감 전 캐시 정리를 수행하지 않는다.

[결과](P02-WORLD-RETURN-NOTICE-RESULT-20261109.md) · [체크리스트](P02-WORLD-RETURN-NOTICE-CHECKLIST-20261109.md) · [적용 기록](../../../tmp/p02-return-notice-20261109/APPLY-RESULT.json)
""",
}
for name, body in files.items():
    with (docs / name).open("x", encoding="utf-8", newline="\n") as stream:
        stream.write(body)
    artifact.add(docs / name)

before = progress.read_bytes()
expected_progress = next(row["sha256"] for row in manifest["baseline"]["files"] if ROOT / row["path"] == progress)
assert hashlib.sha256(before).hexdigest() == expected_progress
newline = b"\r\n" if b"\r\n" in before else b"\n"
anchor = "## 최신 상태 — 전장 → 천하 전환 거절".encode("utf-8")
assert before.count(anchor) == 1
insert = """## 최신 상태 — 천하 복귀 실패 안내

- [x] **즉시 복귀 거절과 재시도 안내.** 일시정지·결과·최초 준비 실패에서 한글 안내를 표시한다. 격리 28개 명령·728개 단언과 1600×900 앱 viewport PNG 18개를 검토했고 네 파일을 반영했다. 준비 화면 버튼은 기준선보다 25px 내려갔다. 원본 반영 후 Godot은 재실행하지 않았다. [결과](P02-WORLD-RETURN-NOTICE-RESULT-20261109.md) · [체크리스트](P02-WORLD-RETURN-NOTICE-CHECKLIST-20261109.md) · [인계](SESSION-HANDOFF-P02-WORLD-RETURN-NOTICE-20261109.md).
- [ ] **전달 독립 마감 대기.** OS 입력·다른 DPI·자연 종료·제품 operation은 미검증이다. PC0 2/2와 별도 여덟째 K6 상태를 유지한다. [전달 ZIP](../../../tmp/p02-return-notice-20261109/P02-WORLD-RETURN-NOTICE-DELIVERY-20261109.zip).

""".encode("utf-8").replace(b"\n", newline)
assert progress.read_bytes() == before
after = before.replace(anchor, insert + anchor, 1)
progress.write_bytes(after)
assert progress.read_bytes().replace(insert + anchor, anchor, 1) == before
progress_delta = BASE / "progress-inserted.md.txt"
progress_delta.write_bytes(insert)
artifact.update((progress, progress_delta))

post = snapshots()
assert pre == post
assert git("rev-parse","HEAD") == apply["head"] and sha(index) == apply["index_sha256"]
for name, old in manifest["source_map"].items():
    assert sha(ROOT / name) == apply["after"].get(name, old), name

audit = BASE / "CLOSEOUT-AUDIT.json"
audit.write_text(json.dumps({
    "utc_before": now, "utc_after": datetime.now(UTC).isoformat(), "sample_kind": "before and after checks, not a filesystem lock",
    "source_count": len(manifest["source_map"]), "head": apply["head"], "index_sha256": apply["index_sha256"],
    "protected_evidence_old_zip_html_sha256": pre, "progress_before_sha256": expected_progress,
    "progress_after_sha256": sha(progress), "progress_insert_sha256": sha(progress_delta),
    "progress_reverse_exact": True, "free_before_bytes": disk_before,
    "engine_reruns": 0, "cache_deleted": False,
}, ensure_ascii=False, indent=2), encoding="utf-8")
artifact.add(audit)

items = {p.relative_to(ROOT).as_posix(): {"sha256": sha(p), "bytes": p.stat().st_size} for p in sorted(artifact)}
inventory = BASE / "DELIVERY-MANIFEST.json"
inventory.write_text(json.dumps({"status": "PENDING_INDEPENDENT_CLOSEOUT", "entries": items}, ensure_ascii=False, indent=2), encoding="utf-8")
zip_path = BASE / f"{stem}-DELIVERY-{day}.zip"
with zipfile.ZipFile(zip_path, "x", compression=zipfile.ZIP_DEFLATED) as z:
    for p in sorted(artifact | {inventory}):
        z.write(p, p.relative_to(ROOT).as_posix())
with zipfile.ZipFile(zip_path) as z:
    assert z.testzip() is None
    assert set(z.namelist()) == set(items) | {inventory.relative_to(ROOT).as_posix()}
    for name, info in items.items():
        assert hashlib.sha256(z.read(name)).hexdigest() == info["sha256"]
receipt = dict(zip_sha256=sha(zip_path), zip_bytes=zip_path.stat().st_size, inventory_sha256=sha(inventory), file_count=len(items)+1, free_after_bytes=shutil.disk_usage(BASE).free)
(BASE/"DELIVERY-RECEIPT.json").write_text(json.dumps(receipt,indent=2),encoding="utf-8")
print(receipt)
