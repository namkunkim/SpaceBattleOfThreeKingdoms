"""Check a successor fencing run bundle for consistency before remote execution."""

import argparse
from hashlib import sha256
import json
from pathlib import Path
import re
from tempfile import TemporaryDirectory
import unittest


ARTIFACTS = ("policy.json", "target-manifest.json")
RECEIPTS = ("host-a.json", "host-b.json")
FIELDS = {"schema", "run_id", "authority_id", "build_sha256", "policy_sha256", "target_sha256"}
HOST_FIELDS = {"schema", "run_id", "authority_id", "build_sha256", "policy_sha256",
               "target_sha256", "os", "machine_id_sha256"}


def read_record(path, fields):
    def unique_pairs(pairs):
        record = {}
        for key, value in pairs:
            if key in record:
                raise ValueError(f"{path.name}: duplicate field {key}")
            record[key] = value
        return record

    record = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_pairs)
    if not isinstance(record, dict) or record.keys() != fields:
        raise ValueError(f"{path.name}: unexpected fields")
    if any(not isinstance(value, str) for value in record.values()):
        raise ValueError(f"{path.name}: expected string fields")
    return record


def verify(bundle):
    request = read_record(bundle / "run.json", FIELDS)
    if request["schema"] != "successor-fencing-preflight/1":
        raise ValueError("run.json: unexpected schema")
    for key in ("run_id", "authority_id"):
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,63}", request[key]):
            raise ValueError(f"run.json: invalid {key}")
    for key in ("build_sha256", "policy_sha256", "target_sha256"):
        if not re.fullmatch(r"[0-9a-f]{64}", request[key]):
            raise ValueError(f"run.json: invalid {key}")
    for name, field in zip(ARTIFACTS, ("policy_sha256", "target_sha256"), strict=True):
        if sha256((bundle / name).read_bytes()).hexdigest() != request[field]:
            raise ValueError(f"{name}: artifact hash differs from run.json")

    machines = set()
    for name in RECEIPTS:
        receipt = read_record(bundle / name, HOST_FIELDS)
        if receipt["schema"] != "successor-fencing-host/1" or receipt["os"] != "Windows":
            raise ValueError(f"{name}: expected a Windows host receipt")
        for key in sorted(FIELDS - {"schema"}):
            if receipt[key] != request[key]:
                raise ValueError(f"{name}: {key} differs from run.json")
        machine = receipt["machine_id_sha256"]
        if not re.fullmatch(r"[0-9a-f]{64}", machine):
            raise ValueError(f"{name}: invalid machine_id_sha256")
        if machine in machines:
            raise ValueError("host receipts use the same machine identity hash")
        machines.add(machine)
    return {"schema": "successor-fencing-preflight-result/1", "status": "bundle-consistent",
            "run_id": request["run_id"], "receipts": list(RECEIPTS)}


class PreflightChecks(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.bundle = Path(temporary.name)
        self.run_record = {"schema": "successor-fencing-preflight/1", "run_id": "synthetic-1",
                           "authority_id": "synthetic-authority", "build_sha256": "1" * 64}
        for name, key in zip(ARTIFACTS, ("policy_sha256", "target_sha256"), strict=True):
            data = json.dumps({"synthetic": name}).encode("utf-8")
            (self.bundle / name).write_bytes(data)
            self.run_record[key] = sha256(data).hexdigest()
        self.write("run.json", self.run_record)
        self.host = {**self.run_record, "schema": "successor-fencing-host/1", "os": "Windows",
                     "machine_id_sha256": "2" * 64}
        self.write("host-a.json", self.host)
        self.write("host-b.json", {**self.host, "machine_id_sha256": "3" * 64})

    def write(self, name, record):
        (self.bundle / name).write_text(json.dumps(record), encoding="utf-8")

    def test_consistent_synthetic_bundle(self):
        self.assertEqual(verify(self.bundle)["status"], "bundle-consistent")

    def test_duplicate_host_identity(self):
        self.write("host-b.json", self.host)
        with self.assertRaisesRegex(ValueError, "same machine identity"):
            verify(self.bundle)

    def test_mismatched_receipt_fields(self):
        for key in ("run_id", "authority_id", "build_sha256", "policy_sha256", "target_sha256"):
            with self.subTest(key=key):
                self.write("host-b.json", {**self.host, key: "mismatch"})
                with self.assertRaisesRegex(ValueError, f"{key} differs"):
                    verify(self.bundle)

    def test_modified_artifacts(self):
        for name in ARTIFACTS:
            with self.subTest(name=name):
                artifact = self.bundle / name
                original = artifact.read_bytes()
                artifact.write_bytes(b'{"changed":true}')
                with self.assertRaisesRegex(ValueError, "artifact hash differs"):
                    verify(self.bundle)
                artifact.write_bytes(original)

    def test_wrong_os_and_missing_receipt(self):
        self.write("host-b.json", {**self.host, "os": "other"})
        with self.assertRaisesRegex(ValueError, "Windows host receipt"):
            verify(self.bundle)
        (self.bundle / "host-b.json").unlink()
        with self.assertRaises(FileNotFoundError):
            verify(self.bundle)

    def test_malformed_or_extended_record(self):
        self.write("host-b.json", {**self.host, "unexpected": "field"})
        with self.assertRaisesRegex(ValueError, "unexpected fields"):
            verify(self.bundle)
        (self.bundle / "host-b.json").write_text('{"os":"Windows","os":"Windows"}',
                                                 encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "duplicate field"):
            verify(self.bundle)

    def test_scope_and_identity_formats(self):
        self.write("run.json", {**self.run_record, "authority_id": "https://invalid.example"})
        with self.assertRaisesRegex(ValueError, "invalid authority_id"):
            verify(self.bundle)
        self.write("run.json", self.run_record)
        self.write("host-b.json", {**self.host, "machine_id_sha256": "not-a-hash"})
        with self.assertRaisesRegex(ValueError, "invalid machine_id_sha256"):
            verify(self.bundle)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--bundle", type=Path)
    action.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        unittest.main(argv=[__file__])
    try:
        result = verify(args.bundle)
    except (OSError, ValueError) as error:
        parser.exit(1, f"preflight failed: {error}\n")
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
