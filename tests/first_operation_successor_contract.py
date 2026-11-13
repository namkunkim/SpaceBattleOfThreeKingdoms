"""Exercise the proposed successor contract against an isolated Godot fixture."""

import argparse
from copy import deepcopy
from dataclasses import dataclass, replace
from hashlib import sha256
import json
from pathlib import Path
import re
import unittest


LEDGER_SHA = "05cd84b424295e9433b6b9712fd095190ca652b516899913786e2f66a26b1e2d"
PARENT_DEFINITION = "red-cliffs-first-operation-dev-v1"
PARENT_ID = PARENT_DEFINITION + "/19364621e32fdb98c13484813be12a89/settlement"
PARENT_FACTS = {
    "id": PARENT_ID, "kind": "failure", "reason": "facility_never_secured",
    "clock_ms": 200, "seed": 208, "mode": "direct", "difficulty": "standard",
}
ACTOR = "fixture-campaign-owner"
CAMPAIGN = "fixture-campaign"


def digest(value):
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return sha256(encoded.encode("utf-8")).hexdigest()


def load_parent(path):
    raw = path.read_bytes()
    if sha256(raw).hexdigest() != LEDGER_SHA:
        raise ValueError("unexpected isolated ledger SHA-256")
    envelope = json.loads(raw)
    if (envelope["format"], envelope["version"]) != ("pc-first-operation-save", 1):
        raise ValueError("unexpected save envelope")
    if sha256(envelope["body"].encode("utf-8")).hexdigest() != envelope["sha256"]:
        raise ValueError("unexpected body SHA-256")
    ledger = json.loads(envelope["body"])
    parent = ledger["consumed"][PARENT_ID]
    if ledger["format"] != "pc-first-operation-settlements/1" or parent != PARENT_FACTS:
        raise ValueError("unexpected parent settlement")
    return ledger


@dataclass(frozen=True)
class Intent:
    campaign: str
    key: str
    generation: int
    parent_id: str
    parent_digest: str
    policy_digest: str
    target_digest: str


@dataclass(frozen=True)
class State:
    generation: int
    eligible_parent: str
    ledger: dict
    transition: dict | None = None


def transition(state, intent, actor, policy):
    """Model a single serialized CAS. Arguments represent one trusted read."""
    if actor != ACTOR or intent.campaign != CAMPAIGN:
        return state, {"error": "forbidden"}
    if not re.fullmatch(r"[a-z0-9-]{1,64}", intent.key):
        return state, {"error": "invalid_intent_key"}

    request_digest = digest(vars(intent))
    committed = state.transition
    if committed and (intent.parent_id, intent.key) == (committed["parent"]["id"], committed["key"]):
        if request_digest != committed["request_digest"]:
            return state, {"error": "intent_conflict"}
        return state, deepcopy(committed)
    if intent.generation != state.generation:
        return state, {"error": "stale_generation"}
    if committed:
        return state, {"error": "parent_already_transitioned"}
    if intent.parent_id != state.eligible_parent:
        return state, {"error": "ineligible_parent"}
    parent = state.ledger["consumed"].get(state.eligible_parent)
    if parent is None or digest(parent) != intent.parent_digest:
        return state, {"error": "parent_mismatch"}
    if policy is None or digest(policy) != intent.policy_digest:
        return state, {"error": "policy_unapproved"}
    if parent["kind"] not in policy["eligible_kinds"]:
        return state, {"error": "ineligible_settlement"}
    target = policy["target"]
    if (target["definition_id"] == PARENT_DEFINITION
            or digest(target) != intent.target_digest):
        return state, {"error": "target_unapproved"}

    transition_id = digest({
        "schema": "successor-proposal/1", "campaign": intent.campaign,
        "parent_digest": intent.parent_digest, "policy_digest": intent.policy_digest,
    })
    record = {
        "id": transition_id, "key": intent.key, "request_digest": request_digest,
        "campaign": intent.campaign, "actor": actor, "generation": state.generation + 1,
        "parent": deepcopy(parent), "parent_digest": intent.parent_digest,
        "policy_digest": intent.policy_digest, "target": deepcopy(target),
        "target_digest": intent.target_digest,
        "operation_id": "fixture-owner/" + transition_id,
        "initial": {
            "tick": 0, "clock_ms": 0, "phase": "brief", "commands": [], "pending": [],
            "settlement": {}, "event_cursor": 0, "proposal_serial": 0,
        },
    }
    return replace(state, generation=state.generation + 1, transition=record), deepcopy(record)


def command_belongs_to_operation(record, operation_id, tick):
    return (record["operation_id"], record["tick"]) == (operation_id, tick)


class ContractChecks(unittest.TestCase):
    ledger = None

    def setUp(self):
        self.state = State(9, PARENT_ID, deepcopy(self.ledger))
        # Opaque references exercise the proposal. They have no product data.
        self.policy = {
            "version": "fixture-policy/1", "eligible_kinds": ["failure"],
            "target": {"definition_id": "fixture-only", "input_manifest": "fixture-only"},
        }
        self.intent = Intent(
            CAMPAIGN, "confirm-1", 9, PARENT_ID, digest(PARENT_FACTS),
            digest(self.policy), digest(self.policy["target"]),
        )

    def reject(self, expected, *, state=None, intent=None, actor=ACTOR, policy=None):
        state = self.state if state is None else state
        frozen = deepcopy(state)
        unchanged, reply = transition(state, intent or self.intent, actor, policy)
        self.assertIs(unchanged, state)
        self.assertEqual(state, frozen)
        self.assertEqual(reply, {"error": expected})

    def test_missing_approval_and_wrong_actor(self):
        self.reject("policy_unapproved")
        self.reject("forbidden", actor="display-view", policy=self.policy)
        self.reject("forbidden", intent=replace(self.intent, campaign="other"), policy=self.policy)
        self.reject("target_unapproved", intent=replace(self.intent, target_digest="wrong"),
                    policy=self.policy)
        self.reject("invalid_intent_key", intent=replace(self.intent, key=""), policy=self.policy)

    def test_explicit_parent_ignores_latest(self):
        ledger = deepcopy(self.ledger)
        other_id = PARENT_DEFINITION + "/" + "0" * 32 + "/settlement"
        ledger["consumed"][other_id] = {**PARENT_FACTS, "id": other_id}
        ledger["latest"] = other_id
        authority = replace(self.state, ledger=ledger)
        self.reject("ineligible_parent", state=authority,
                    intent=replace(self.intent, parent_id=other_id), policy=self.policy)
        _, reply = transition(authority, self.intent, ACTOR, self.policy)
        self.assertEqual(reply["parent"], PARENT_FACTS)

    def test_wrong_parent_content_and_outcome(self):
        changed = deepcopy(self.state)
        changed.ledger["consumed"][PARENT_ID]["reason"] = "changed"
        self.reject("parent_mismatch", state=changed, policy=self.policy)
        policy = {**self.policy, "eligible_kinds": ["objective_success"]}
        self.reject("ineligible_settlement", intent=replace(self.intent, policy_digest=digest(policy)),
                    policy=policy)

    def test_same_definition_reentry_is_separate(self):
        policy = {**self.policy, "target": {"definition_id": PARENT_DEFINITION}}
        intent = replace(self.intent, policy_digest=digest(policy), target_digest=digest(policy["target"]))
        self.reject("target_unapproved", intent=intent, policy=policy)

    def test_commit_maps_only_provenance_and_c0_baseline(self):
        committed, reply = transition(self.state, self.intent, ACTOR, self.policy)
        self.assertEqual(committed.generation, 10)
        self.assertEqual(self.state.ledger, committed.ledger)
        self.assertEqual(reply["parent"], PARENT_FACTS)
        self.assertEqual(reply["parent_digest"], digest(PARENT_FACTS))
        self.assertEqual(reply["target"], self.policy["target"])
        self.assertEqual(reply["target_digest"], self.intent.target_digest)
        self.assertEqual(reply["policy_digest"], self.intent.policy_digest)
        self.assertEqual(reply["initial"], {
            "tick": 0, "clock_ms": 0, "phase": "brief", "commands": [], "pending": [],
            "settlement": {}, "event_cursor": 0, "proposal_serial": 0,
        })
        self.assertNotEqual(reply["operation_id"], PARENT_ID.removesuffix("/settlement"))
        reply["parent"]["seed"] = 999
        self.assertEqual(committed.transition["parent"]["seed"], 208)

    def test_local_command_cursor_is_scoped(self):
        _, reply = transition(self.state, self.intent, ACTOR, self.policy)
        parent = {"operation_id": PARENT_ID.removesuffix("/settlement"), "tick": 0}
        successor = {"operation_id": reply["operation_id"], "tick": 0}
        self.assertFalse(command_belongs_to_operation(parent, successor["operation_id"], 0))
        self.assertTrue(command_belongs_to_operation(successor, successor["operation_id"], 0))

    def test_retry_before_commit_and_after_response_loss(self):
        proposed, reply = transition(self.state, self.intent, ACTOR, self.policy)
        self.assertIsNone(self.state.transition)  # Lose the proposal before CAS.
        committed, retry = transition(self.state, self.intent, ACTOR, self.policy)
        self.assertEqual((committed, retry), (proposed, reply))
        restarted = deepcopy(committed)  # Model reloading an already committed generation.
        same, replay = transition(restarted, self.intent, ACTOR, None)
        self.assertIs(same, restarted)
        self.assertEqual(replay, reply)
        self.reject("forbidden", state=restarted, actor="other")

    def test_competing_intents_and_changed_request(self):
        committed, _ = transition(self.state, self.intent, ACTOR, self.policy)
        competing = replace(self.intent, key="confirm-2")
        self.reject("stale_generation", state=committed, intent=competing, policy=self.policy)
        self.reject("parent_already_transitioned", state=committed,
                    intent=replace(competing, generation=10), policy=self.policy)
        self.reject("intent_conflict", state=committed,
                    intent=replace(self.intent, target_digest="different"), policy=self.policy)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("isolated_ledger", type=Path)
    args = parser.parse_args()
    ContractChecks.ledger = load_parent(args.isolated_ledger)
    unittest.main(argv=[__file__], verbosity=2)
