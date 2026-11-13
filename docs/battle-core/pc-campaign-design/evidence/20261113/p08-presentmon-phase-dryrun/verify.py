import csv
import hashlib
import json
import statistics
import sys
from pathlib import Path

run = Path(__file__).resolve().parent
gold_path = Path(sys.argv[1])
card_path = run / "card.csv"

def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        return reader.fieldnames, list(reader)

columns, rows = read_csv(card_path)
gold_columns, gold = read_csv(gold_path)
removed = {
    "FrameType", "VideoBusy", "AllInputToPhotonLatency",
    "ClickToPhotonLatency", "InstrumentedLatency",
}
assert set(gold_columns) - set(columns) == removed
assert len(columns) == 21 and len(rows) == 56
assert rows == [{column: row[column] for column in columns} for row in gold]
pid = "1300"
swapchain = "0x296989CD030"
assert all(row["ProcessID"] == pid and row["SwapChainAddress"] == swapchain for row in rows)
first, split, last = (int(rows[index]["CPUStartQPC"]) for index in (0, 4, 7))

def phase(records, start, end):
    selected = [
        row for row in records
        if row["ProcessID"] == pid and row["SwapChainAddress"] == swapchain
        and start <= int(row["CPUStartQPC"]) < end
    ]
    display = [float(row["DisplayedTime"]) for row in selected if row["DisplayedTime"] not in ("", "NA")]
    frame = [float(row["FrameTime"]) for row in selected if row["FrameTime"] not in ("", "NA")]
    return {
        "count": len(selected), "frame_time_sample_count": len(frame),
        "frame_time_median_ms": statistics.median(frame) if frame else None,
        "displayed_time_sample_count": len(display),
        "displayed_time_median_ms": statistics.median(display) if display else None,
        "not_displayed_count": sum(row["DisplayedTime"] == "NA" for row in selected),
        "unknown_displayed_time_count": sum(row["DisplayedTime"] == "" for row in selected),
    }

original = [phase(rows, first, split), phase(rows, split, last)]
assert [item["count"] for item in original] == [4, 3]
# Inject unrelated PID/swapchain records exactly on the shared phase boundary.
foreign = [dict(rows[4], ProcessID="99999"), dict(rows[4], SwapChainAddress="0xDEADBEEF")]
assert phase(rows + foreign, split, last) == original[1]
# A documented v2 NA and an absent field take separate paths.
injected = [
    dict(row, DisplayedTime=value)
    for row, value in zip(rows[:4], ("NA", "", "8.0", "12.0"), strict=True)
]
assert phase(injected + foreign, first, split) == {
    **original[0], "displayed_time_sample_count": 2, "displayed_time_median_ms": 10.0,
    "not_displayed_count": 1, "unknown_displayed_time_count": 1,
}
assert phase(rows, last, last)["count"] == 0
result = {
    "card_sha256": hashlib.sha256(card_path.read_bytes()).hexdigest(),
    "gold_filtered_sha256": hashlib.sha256(gold_path.read_bytes()).hexdigest(),
    "card_columns": columns, "removed_columns": sorted(removed), "replayed_rows": len(rows),
    "phase_boundary_qpc": [first, split, last], "phase_results": original,
    "mixed_pid_swapchain_control": "pass", "na_blank_numeric_control": "pass",
    "empty_window_control": "pass",
}
(run / "RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps(result, indent=2))