"""Exercise durable successor CAS across independent local worker processes."""

import argparse
from contextlib import closing
from dataclasses import replace
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import time

from first_operation_successor_contract import ACTOR, CAMPAIGN, PARENT_FACTS, PARENT_ID
from first_operation_successor_contract import Intent, State, digest, load_parent, transition


def connect(path):
    db = sqlite3.connect(path, timeout=10, isolation_level=None)
    db.execute("PRAGMA synchronous=FULL")
    return db


def initialize(path, ledger, policy):
    with closing(connect(path)) as db:
        db.executescript("""
            CREATE TABLE authority (
                campaign TEXT PRIMARY KEY, generation INTEGER NOT NULL,
                parent_id TEXT NOT NULL, ledger TEXT NOT NULL, policy TEXT
            );
            CREATE TABLE transitions (
                campaign TEXT NOT NULL, parent_id TEXT NOT NULL, intent_key TEXT NOT NULL,
                response TEXT NOT NULL, PRIMARY KEY (campaign, parent_id),
                UNIQUE (campaign, parent_id, intent_key)
            );
        """)
        db.execute("INSERT INTO authority VALUES (?, 9, ?, ?, ?)",
                   (CAMPAIGN, PARENT_ID, json.dumps(ledger), json.dumps(policy)))


def apply(path, intent, actor, crash):
    with closing(connect(path)) as db:
        db.execute("BEGIN IMMEDIATE")
        generation, parent, ledger, policy = db.execute(
            "SELECT generation, parent_id, ledger, policy FROM authority WHERE campaign=?",
            (CAMPAIGN,),
        ).fetchone()
        row = db.execute("SELECT response FROM transitions WHERE campaign=? AND parent_id=?",
                         (CAMPAIGN, intent.parent_id)).fetchone()
        state = State(generation, parent, json.loads(ledger), json.loads(row[0]) if row else None)
        next_state, response = transition(state, intent, actor, json.loads(policy))
        if next_state is not state:
            changed = db.execute(
                "UPDATE authority SET generation=? WHERE campaign=? AND generation=? AND parent_id=?",
                (next_state.generation, CAMPAIGN, intent.generation, intent.parent_id),
            )
            if changed.rowcount != 1:
                raise RuntimeError("generation CAS failed inside writer transaction")
            db.execute("INSERT INTO transitions VALUES (?, ?, ?, ?)",
                       (CAMPAIGN, parent, intent.key, json.dumps(response)))
        if next_state is not state and crash == "before":
            os._exit(71)
        db.execute("COMMIT")
        if next_state is not state and crash == "after":
            os._exit(72)
        return response


def worker(db, raw_intent, actor, crash, gate, ready):
    if gate:
        Path(ready).touch(exist_ok=False)
        wait_for(lambda: Path(gate).exists())
    print(json.dumps({"pid": os.getpid(), "reply": apply(db, Intent(**json.loads(raw_intent)), actor, crash)}))


def wait_for(predicate):
    deadline = time.monotonic() + 10
    while not predicate():
        if time.monotonic() >= deadline:
            raise TimeoutError("worker synchronization timed out")
        time.sleep(0.01)


def launch(db, intent, actor=ACTOR, crash="", gate="", ready=""):
    return subprocess.Popen(
        [sys.executable, "-B", __file__, "--worker", str(db), json.dumps(vars(intent)), actor,
         crash, str(gate), str(ready)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )


def collect(process, expected=0):
    stdout, stderr = process.communicate(timeout=15)
    require(process.returncode == expected and not stderr, (process.returncode, stderr))
    if expected:
        require(not stdout, "crash unexpectedly returned a response")
        return {}
    result = json.loads(stdout)
    require(result["pid"] == process.pid and process.pid != os.getpid(), result)
    return result["reply"]


def require(condition, details):
    if not condition:
        raise AssertionError(details)


def inspect(db):
    with closing(connect(db)) as connection:
        generation, ledger = connection.execute("SELECT generation, ledger FROM authority").fetchone()
        count, = connection.execute("SELECT count(*) FROM transitions").fetchone()
        return generation, count, json.loads(ledger)


def race(directory, db, first, second):
    gate = directory / "go"
    ready_a, ready_b = directory / "ready-a", directory / "ready-b"
    workers = [launch(db, first, gate=gate, ready=ready_a),
               launch(db, second, gate=gate, ready=ready_b)]
    try:
        wait_for(lambda: ready_a.exists() and ready_b.exists())
        require(workers[0].pid != workers[1].pid, "expected independent process IDs")
        print(f"worker PIDs {workers[0].pid}, {workers[1].pid}")
        gate.touch(exist_ok=False)
        return [collect(process) for process in workers]
    finally:
        for process in workers:
            if process.poll() is None:
                process.kill()
                process.communicate()


def run(fixture, temporary_parent):
    ledger = load_parent(fixture)
    original = fixture.read_bytes()
    policy = {"version": "fixture-policy/1", "eligible_kinds": ["failure"],
              "target": {"definition_id": "fixture-only", "input_manifest": "fixture-only"}}
    intent = Intent(CAMPAIGN, "confirm-1", 9, PARENT_ID, digest(PARENT_FACTS),
                    digest(policy), digest(policy["target"]))
    with tempfile.TemporaryDirectory(dir=temporary_parent) as temporary:
        root = Path(temporary)
        for mode in ("same", "different"):
            directory = root / mode
            directory.mkdir()
            db = directory / "test.sqlite"
            initialize(db, ledger, policy)
            second = intent if mode == "same" else replace(intent, key="confirm-2")
            replies = race(directory, db, intent, second)
            if mode == "same":
                require(replies[0] == replies[1] and "id" in replies[0], replies)
            else:
                require(sum("id" in reply for reply in replies) == 1, replies)
                require({"error": "stale_generation"} in replies, replies)
            require(inspect(db) == (10, 1, ledger), inspect(db))
            print(f"PASS concurrent {mode} intents")

        db = root / "crash.sqlite"
        initialize(db, ledger, policy)
        collect(launch(db, intent, crash="before"), 71)
        require(inspect(db) == (9, 0, ledger), inspect(db))
        collect(launch(db, intent, crash="after"), 72)
        require(inspect(db) == (10, 1, ledger), inspect(db))
        replay = collect(launch(db, intent))
        with closing(connect(db)) as connection:
            persisted, = connection.execute("SELECT response FROM transitions").fetchone()
        require(replay == json.loads(persisted) and "id" in replay, replay)
        require(collect(launch(db, replace(intent, target_digest="changed"))) ==
                {"error": "intent_conflict"}, "changed retry")
        require(collect(launch(db, intent, actor="read-only-view")) ==
                {"error": "forbidden"}, "forged actor")
        with closing(connect(db)) as connection:
            connection.execute("UPDATE authority SET generation=11, parent_id='next-parent'")
        require(collect(launch(db, intent)) == replay, "historical retry after parent advances")
        require(inspect(db) == (11, 1, ledger), inspect(db))
        print("PASS before-commit rollback and after-commit response recovery")

        stale_db = root / "stale.sqlite"
        initialize(stale_db, ledger, policy)
        with closing(connect(stale_db)) as connection:
            connection.execute("UPDATE authority SET generation=10")
        require(collect(launch(stale_db, intent)) == {"error": "stale_generation"}, "stale generation")
        with closing(connect(stale_db)) as connection:
            connection.execute("UPDATE authority SET policy='null'")
        require(collect(launch(stale_db, replace(intent, generation=10))) ==
                {"error": "policy_unapproved"}, "withdrawn authority")
        require(inspect(stale_db) == (10, 0, ledger), inspect(stale_db))
        print("PASS stale and withdrawn authority")
    require(original == fixture.read_bytes(), "source fixture was mutated")
    print("PASS source ledger byte-identical")


if __name__ == "__main__":
    if sys.argv[1:2] == ["--worker"]:
        worker(*sys.argv[2:])
    else:
        parser = argparse.ArgumentParser(description=__doc__)
        parser.add_argument("isolated_ledger", type=Path)
        parser.add_argument("temporary_parent", type=Path)
        args = parser.parse_args()
        run(args.isolated_ledger, args.temporary_parent)
