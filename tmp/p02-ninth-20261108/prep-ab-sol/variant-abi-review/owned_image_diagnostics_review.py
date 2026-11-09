"""Source-only ownership diagnostics for a future, separately reviewed probe."""
from dataclasses import asdict, dataclass
import json
import ntpath

MAX_RECORD_BYTES=262144

@dataclass(frozen=True)
class Observation:
    stage: str
    pid: int
    outcome: str
    member_before: bool | None = None
    member_after: bool | None = None
    creation_time: int | None = None
    image_raw: str | None = None
    image_normalized: str | None = None
    expected_images: tuple[str,...] = ()

def normalized(path):
    if type(path) is not str or not ntpath.isabs(path) or "\0" in path:
        raise ValueError("invalid Windows image path")
    # A comparison spelling only. Never open or resolve the unexpected image.
    return ntpath.normcase(ntpath.normpath(path))

def observe(api,handle,listed_pid,stage,expected_images,prior_creation=None):
    """Inspect only a retained HANDLE from the exact owned Job."""
    if type(listed_pid) is not int or listed_pid<=0:
        raise ValueError("invalid listed PID")
    allowed=tuple(expected_images)
    expected=tuple(normalized(path) for path in allowed)
    def record(outcome,**details):
        return Observation(stage,listed_pid,outcome,expected_images=allowed,**details)
    if not api.in_job(handle):
        return record("not-owned",member_before=False)
    if api.signalled(handle):
        return record("short-lived-before-inspection",member_before=True)
    if api.pid(handle)!=listed_pid:
        return record("pid-mismatch",member_before=True)
    created=api.creation_time(handle)
    if type(created) is not int or created<=0:
        return record("creation-time-unavailable",member_before=True)
    if prior_creation is not None and prior_creation!=created:
        return record("pid-reuse",member_before=True,creation_time=created)
    image=api.image(handle)
    if image is None:
        return record("image-unavailable",member_before=True,creation_time=created)
    if not api.in_job(handle):
        # Drop the image entirely if ownership is not independently rechecked.
        return record("membership-lost",member_before=True,member_after=False,creation_time=created)
    if api.signalled(handle):
        return record("short-lived-during-inspection",member_before=True,member_after=True,creation_time=created)
    if api.pid(handle)!=listed_pid or api.creation_time(handle)!=created:
        return record("identity-changed-during-inspection",member_before=True,member_after=True,creation_time=created)
    try:
        image_compare=normalized(image)
    except ValueError:
        return record("invalid-image-path",member_before=True,member_after=True,creation_time=created)
    return record("allowed" if image_compare in expected else "unexpected-owned-image",
                  member_before=True,member_after=True,creation_time=created,
                  image_raw=image,image_normalized=image_compare)

@dataclass
class Failures:
    first: dict | None = None
    cleanup: dict | None = None

    def set_first(self,code,observation=None):
        if self.first is None:
            self.first={"code":code,"observation":asdict(observation) if observation else None}

    def set_cleanup(self,code,drained):
        if self.cleanup is None:
            self.cleanup={"code":code,"drained":drained}

    def serialize(self):
        if self.first is None:
            raise ValueError("missing primary diagnostic")
        if self.cleanup is None:
            raise ValueError("missing cleanup receipt")
        data=(json.dumps(asdict(self),ensure_ascii=False,separators=(",",":"))+"\n").encode("utf8")
        if len(data)>MAX_RECORD_BYTES:
            raise ValueError("diagnostic cap exceeded; evidence incomplete")
        return data
