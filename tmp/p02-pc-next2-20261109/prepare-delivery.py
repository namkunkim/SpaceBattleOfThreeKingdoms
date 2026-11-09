"""Record the single progress insertion and prepare a curated, hash-checked ZIP."""
import hashlib
import json
import runpy
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
DOC = ROOT / "docs/battle-core/pc-campaign-design"
OLD = BASE.parent / "p02-pc-next-20261109"
DELIVERY = BASE / "delivery-precloseout"
PROGRESS = DOC / "P02-PROGRESS-CHECKLIST.md"
LINK = "scripts/world_link.gd"


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def put(path, obj):
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(obj, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


runner = runpy.run_path(str(BASE / "run-reviewed-return-v2.py"))
manifest = read(BASE / "ATTEMPT-02-EXECUTION-REVIEW-ONLY.json")
approved = sha(BASE / "world_link.candidate.gd.txt")
manifest["source_map"][LINK] = approved
for row in manifest["baseline"]["files"]:
    if row["path"] == LINK:
        row["sha256"] = approved
runner["verify"](manifest)

old_baseline = read(OLD / "baseline.json")
old_media = {
    path: digest for rows in old_baseline["files"].values() for path, digest in rows.items()
    if Path(path).suffix.lower() in (".zip", ".html")
}
prior_delivery = OLD / "delivery-precloseout/P02-DIRECT-SCENE-REJECT-DELIVERY-20261109.zip"
old_media[prior_delivery.relative_to(ROOT).as_posix()] = "491a6d55c2bd870c4f7b3f82b2913a0acf771baf4fe4768a93bd9d0473b1c7bd"
assert all(sha(ROOT / path) == digest for path, digest in old_media.items())

before = PROGRESS.read_bytes()
anchor = "## 최신 상태 — 직접 출격 장면 전환 거절".encode()
assert before.count(anchor) == 1
section = """## 최신 상태 — 전장 → 천하 전환 거절

- [x] **기존 복귀의 즉시 전환 오류 복구.** 결과·일시정지·최초 준비 실패의 실제 로더 거절에서 Brief와 이전 대기 Outcome 참조를 복원한다. 2회차 격리 20개 실행·210개 단언을 통과했다. 후보는 각 경로에서 실제 거절 두 번 뒤 같은 전장과 버튼으로 재시도했다. 원본 한 함수 반영과 후보 바이트 일치, 기존 출격 hunk 보존을 독립 확인했다. 반영 뒤 Godot은 미실행이다. [결과](P02-WORLD-RETURN-REJECT-RESULT-20261109.md) · [체크리스트](P02-WORLD-RETURN-REJECT-CHECKLIST-20261109.md) · [인계](SESSION-HANDOFF-P02-WORLD-RETURN-REJECT-20261109.md).
- [ ] **전달 독립 마감.** ZIP 생성 시점의 상태다. 이 조각 2/6회 사용. PC0 2/2 소진, 별도 여덟째 K6 미실행, 첫 PC 플레이·자연 종료·제품 operation은 미인수다. [전달 ZIP](../../../tmp/p02-pc-next2-20261109/delivery-precloseout/P02-WORLD-RETURN-REJECT-DELIVERY-20261109.zip).

""".encode()
if b"\r\n" in before:
    section = section.replace(b"\n", b"\r\n")
assert section not in before
after = before.replace(anchor, section + anchor, 1)
assert after.replace(section, b"", 1) == before
DELIVERY.mkdir()
with (DELIVERY / "progress.before.md.txt").open("xb") as stream:
    stream.write(before)
with (DELIVERY / "progress.inserted.md.txt").open("xb") as stream:
    stream.write(section)
with PROGRESS.open("r+b") as stream:
    assert stream.read() == before
    stream.seek(0)
    stream.write(after)
    stream.truncate()
assert PROGRESS.read_bytes() == after
progress_sha = sha(PROGRESS)
for row in manifest["baseline"]["files"]:
    if row["path"] == PROGRESS.relative_to(ROOT).as_posix():
        row["sha256"] = progress_sha
runner["verify"](manifest)
assert all(sha(ROOT / path) == digest for path, digest in old_media.items())
put(DELIVERY / "preservation.json", {
    "branch": manifest["baseline"]["branch"], "head": manifest["baseline"]["head"],
    "index_sha": manifest["baseline"]["index_sha256_after"], "source_paths_verified": len(manifest["source_map"]),
    "baseline_paths_verified": len(manifest["baseline"]["files"]), "old_zip_html_sha256": old_media,
    "world_link_sha256": approved, "progress_before_sha256": hashlib.sha256(before).hexdigest(),
    "progress_after_sha256": progress_sha, "progress_exact_reverse": True,
})

payload = {PROGRESS, ROOT / LINK, ROOT / "view/world/world_map_screen.gd"}
payload.update(DOC.glob("*P02-WORLD-RETURN-REJECT*-20261109.md"))
payload.update(path for path in BASE.iterdir() if path.is_file())
payload.update(path for path in DELIVERY.iterdir() if path.is_file())
payload.update(OLD / name for name in ("launch-direct.ps1", "P02DirectJob.cs", "world-link-prepared-v6.gd.txt"))
payload.add(BASE.parent / "p02-sixth-20261108/returning-settings.cfg")
for attempt in ("attempt-01", "attempt-02"):
    run = BASE / attempt
    payload.add(run / "results.json")
    for side in ("before", "after"):
        for lane in (run / side).iterdir():
            if lane.name == "project":
                continue
            payload.update(path for path in lane.iterdir() if path.is_file())
entries = {path.relative_to(ROOT).as_posix(): {"size": path.stat().st_size, "sha256": sha(path)} for path in sorted(payload)}
manifest_path = DELIVERY / "manifest.json"
put(manifest_path, {"kind": "curated-precloseout-evidence", "closeout": "pending", "entries": entries})
archive = DELIVERY / "P02-WORLD-RETURN-REJECT-DELIVERY-20261109.zip"
manifest_name = manifest_path.relative_to(ROOT).as_posix()
with ZipFile(archive, "x", compression=ZIP_DEFLATED, compresslevel=6) as out:
    for name in entries:
        out.write(ROOT / name, name)
    out.write(manifest_path, manifest_name)
with ZipFile(archive) as check:
    names = check.namelist()
    assert len(names) == len(set(names)) == len(entries) + 1 and set(names) == set(entries) | {manifest_name}
    assert check.testzip() is None
    for name, expected in entries.items():
        data = check.read(name)
        assert len(data) == expected["size"] and hashlib.sha256(data).hexdigest() == expected["sha256"]
        assert sha(ROOT / name) == expected["sha256"]
    assert check.read(manifest_name) == manifest_path.read_bytes()
put(DELIVERY / "verification.json", {
    "archive_sha256": sha(archive), "archive_bytes": archive.stat().st_size,
    "manifest_sha256": sha(manifest_path), "payload_count": len(entries), "zip_entries": len(names),
    "crc": "PASS", "duplicates": 0, "same_workspace_payload_bytes": True,
})
print(read(DELIVERY / "verification.json"))
