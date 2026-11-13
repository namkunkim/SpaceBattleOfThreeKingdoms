"""Exercise durable successor fencing with synthetic time and local processes."""

import argparse
from base64 import urlsafe_b64decode, urlsafe_b64encode
from contextlib import closing
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from first_operation_successor_contract import (
    ACTOR, CAMPAIGN, PARENT_FACTS, PARENT_ID, Intent, State, digest, load_parent, transition,
)
from first_operation_successor_persistence import connect, wait_for


LEASE_TICKS = 10


def initialize(path, ledger):
    # Derive the successor identity through the existing contract model.
    policy = {"version": "fixture-policy/1", "eligible_kinds": ["failure"],
              "target": {"definition_id": "fixture-only", "input_manifest": "fixture-only"}}
    intent = Intent(CAMPAIGN, "confirm-1", 9, PARENT_ID, digest(PARENT_FACTS),
                    digest(policy), digest(policy["target"]))
    _, successor = transition(State(9, PARENT_ID, ledger), intent, ACTOR, policy)
    operation = successor["operation_id"]
    with closing(connect(path)) as db:
        db.executescript("""
            CREATE TABLE owners (
                operation TEXT PRIMARY KEY, owner TEXT, epoch INTEGER NOT NULL,
                expires INTEGER NOT NULL
            );
            CREATE TABLE effects (
                operation TEXT NOT NULL, effect_id TEXT NOT NULL,
                payload_digest TEXT NOT NULL, committed_epoch INTEGER NOT NULL,
                PRIMARY KEY (operation, effect_id)
            );
        """)
        db.execute("INSERT INTO owners VALUES (?, NULL, 0, 0)", (operation,))
    return operation


def apply(path, action, operation, owner, now, epoch, effect_id, payload, crash):
    # The harness supplies the service clock. Each worker opens a fresh connection.
    with closing(connect(path)) as db:
        db.execute("BEGIN IMMEDIATE")
        current = db.execute(
            "SELECT owner, epoch, expires FROM owners WHERE operation=?", (operation,),
        ).fetchone()
        if current is None:
            return {"error": "unknown_operation"}
        current_owner, current_epoch, expires = current

        if action == "acquire":
            if now < expires:
                return {"error": "lease_active"}
            epoch = current_epoch + 1
            expires = now + LEASE_TICKS
            db.execute("UPDATE owners SET owner=?, epoch=?, expires=? WHERE operation=?",
                       (owner, epoch, expires, operation))
            response = {"epoch": epoch, "expires": expires}
        elif action == "effect":
            # Fence before checking idempotency so a stale writer cannot use either
            # a fresh effect ID or a previously committed effect to bypass the guard.
            if (owner, epoch) != (current_owner, current_epoch) or now >= expires:
                return {"error": "stale_owner"}
            payload_digest = digest(payload)
            existing = db.execute(
                "SELECT payload_digest, committed_epoch FROM effects "
                "WHERE operation=? AND effect_id=?", (operation, effect_id),
            ).fetchone()
            if existing:
                if existing[0] != payload_digest:
                    return {"error": "effect_conflict"}
                return {"effect_id": effect_id, "committed_epoch": existing[1]}
            db.execute("INSERT INTO effects VALUES (?, ?, ?, ?)",
                       (operation, effect_id, payload_digest, epoch))
            response = {"effect_id": effect_id, "committed_epoch": epoch}
        else:
            raise ValueError(f"unknown worker action: {action}")

        if crash == "before":
            os._exit(71)
        db.execute("COMMIT")
        if crash == "after":
            os._exit(72)
        return response


class FencingChecks(unittest.TestCase):
    temporary_parent = None
    ledger = None

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(dir=self.temporary_parent)
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "fencing.sqlite"
        self.operation = initialize(self.path, self.ledger)

    def launch(self, action, owner, now, *, epoch=0, effect_id="", payload=None,
               crash="", operation=None, gate=None, ready=None):
        request = [action, operation or self.operation, owner, now, epoch, effect_id, payload, crash]
        encoded = urlsafe_b64encode(json.dumps(request).encode("utf-8")).decode("ascii")
        command = [sys.executable, "-B", __file__, str(self.path), f"--worker={encoded}"]
        if gate is not None:
            command += ["--gate", str(gate), "--ready", str(ready)]
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        self.addCleanup(self.reap, process)
        return process

    @staticmethod
    def reap(process):
        if process.poll() is None:
            process.kill()
            process.communicate()

    def collect(self, process, status=0):
        stdout, stderr = process.communicate(timeout=15)
        self.assertEqual(process.returncode, status, stderr)
        self.assertEqual(stderr, "")
        if status:
            self.assertEqual(stdout, "")
            return None
        result = json.loads(stdout)
        self.assertEqual(result["pid"], process.pid)
        self.assertNotEqual(result["pid"], os.getpid())
        return result["reply"]

    def request(self, action, owner, now, *, status=0, **fields):
        return self.collect(self.launch(action, owner, now, **fields), status)

    def effects(self):
        with closing(connect(self.path)) as db:
            return db.execute(
                "SELECT effect_id, payload_digest, committed_epoch FROM effects ORDER BY effect_id",
            ).fetchall()

    def test_one_owner_and_expiry_fence(self):
        hosts = ("worker-a", "worker-b")
        gate = self.path.with_name("go")
        ready = [self.path.with_name(host) for host in hosts]
        first, second = (self.launch("acquire", host, 10, gate=gate, ready=marker)
                         for host, marker in zip(hosts, ready, strict=True))
        self.assertNotEqual(first.pid, second.pid)
        wait_for(lambda: all(marker.exists() for marker in ready))
        gate.touch(exist_ok=False)
        replies = [self.collect(first), self.collect(second)]
        self.assertCountEqual(replies, [{"epoch": 1, "expires": 20}, {"error": "lease_active"}])
        winner, loser = hosts if "epoch" in replies[0] else hosts[::-1]
        effect = {"effect_id": "advance", "payload": {"tick": 1}}
        self.assertEqual(self.request("effect", loser, 19, epoch=1, **effect),
                         {"error": "stale_owner"})
        self.assertEqual(self.request("effect", winner, 20, epoch=1, **effect),
                         {"error": "stale_owner"})
        self.assertEqual(self.request("acquire", loser, 20), {"epoch": 2, "expires": 30})
        self.assertEqual(self.request("effect", winner, 20, epoch=1, **effect),
                         {"error": "stale_owner"})
        self.assertEqual(self.request("effect", loser, 20, epoch=2, **effect),
                         {"effect_id": "advance", "committed_epoch": 2})
        self.assertEqual(self.request("acquire", loser, 30), {"epoch": 3, "expires": 40})
        self.assertEqual(self.request("effect", loser, 30, epoch=2, **effect),
                         {"error": "stale_owner"})
        self.assertEqual(self.effects(), [("advance", digest(effect["payload"]), 2)])

    def test_effect_recovery_and_conflict(self):
        self.assertEqual(self.request("acquire", "worker-a", 10), {"epoch": 1, "expires": 20})
        effect = {"effect_id": "advance", "payload": {"tick": 1}}
        self.request("effect", "worker-a", 11, epoch=1, crash="before", status=71, **effect)
        self.assertEqual(self.effects(), [])
        self.request("effect", "worker-a", 12, epoch=1, crash="after", status=72, **effect)
        result = {"effect_id": "advance", "committed_epoch": 1}
        self.assertEqual(self.request("effect", "worker-a", 13, epoch=1, **effect), result)
        self.assertEqual(self.request("acquire", "worker-b", 20), {"epoch": 2, "expires": 30})
        self.assertEqual(self.request("effect", "worker-a", 20, epoch=1, **effect),
                         {"error": "stale_owner"})
        self.assertEqual(self.request("effect", "worker-b", 20, epoch=2, **effect), result)
        self.assertEqual(self.request("effect", "worker-b", 20, epoch=2,
                                      effect_id="advance", payload={"tick": 2}),
                         {"error": "effect_conflict"})
        self.assertEqual(self.effects(), [("advance", digest(effect["payload"]), 1)])

    def test_acquire_recovery(self):
        self.request("acquire", "worker-a", 10, crash="before", status=71)
        self.assertEqual(self.request("acquire", "worker-b", 10), {"epoch": 1, "expires": 20})
        self.request("acquire", "worker-a", 20, crash="after", status=72)
        self.assertEqual(self.request("acquire", "worker-b", 20), {"error": "lease_active"})
        self.assertEqual(self.request("acquire", "worker-b", 30), {"epoch": 3, "expires": 40})

    def test_unregistered_operation_cannot_acquire_or_write(self):
        for action in ("acquire", "effect"):
            self.assertEqual(self.request(action, "worker-a", 10, operation="unregistered"),
                             {"error": "unknown_operation"})
        self.assertEqual(self.effects(), [])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path, help="isolated settlement fixture or worker database")
    parser.add_argument("temporary_parent", type=Path, nargs="?")
    parser.add_argument("--worker", metavar="REQUEST")
    parser.add_argument("--gate", type=Path)
    parser.add_argument("--ready", type=Path)
    args = parser.parse_args()
    if args.worker is not None:
        if args.gate is not None:
            args.ready.touch(exist_ok=False)
            wait_for(args.gate.exists)
        reply = apply(args.path, *json.loads(urlsafe_b64decode(args.worker)))
        print(json.dumps({"pid": os.getpid(), "reply": reply}))
        return
    if args.temporary_parent is None:
        parser.error("temporary_parent is required")
    FencingChecks.ledger = load_parent(args.path)
    FencingChecks.temporary_parent = args.temporary_parent
    unittest.main(argv=[sys.argv[0]])


if __name__ == "__main__":
    main()
