"""Synthetic one-effect receiver. Its state is neither durable nor a product contract."""
from dataclasses import dataclass, field


@dataclass
class Receiver:
    context: str = "A"
    marked: bool = False
    amount: int = 0
    notifications: list[str] = field(default_factory=list)

    def state(self):
        return [self.context, self.marked, self.amount]

    def receive(self, context):
        if context != self.context:
            return "context_mismatch"
        if self.marked:
            return "skipped"
        self.amount += 1
        self.marked = True
        return "applied"

    def notify(self, key):
        self.notifications.append(key)

    def interrupt(self, order):
        if order == "marker_first":
            self.marked = True
        elif order == "effect_first":
            self.amount += 1
        elif order == "rollback":
            prior = self.marked, self.amount
            self.amount += 1
            self.marked, self.amount = prior
        else:
            raise ValueError(order)
        return "interrupted"


def observe(case):
    owner = Receiver()
    if case == "projection_only":
        owner.notify("K")
        initial = owner.state()
        owner.notify("K")
        operation = ["notified", "notified"]
    elif case == "wrong_context":
        initial = owner.state()
        operation = [owner.receive("B")]
    else:
        order = {
            "marker_first_interruption": "marker_first",
            "effect_first_interruption": "effect_first",
            "rollback_countermodel": "rollback",
        }.get(case)
        first = owner.interrupt(order) if order else owner.receive("A")
        initial = owner.state()
        operation = [first, owner.receive("A")]
    final = owner.state()
    return [initial, final, {
        "complete": owner.marked and owner.amount == 1,
        "operations": operation,
        "notifications": owner.notifications,
    }]
