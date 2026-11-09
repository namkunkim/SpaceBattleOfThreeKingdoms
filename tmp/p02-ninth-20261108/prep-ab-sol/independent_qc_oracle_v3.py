"""Additional end-to-end field/bytes validation on both capture streams."""
import argparse
import json
from pathlib import Path
from independent_qc_oracle import check_q,check_c,historical_cases
from legacy_autoresolve_oracle import need, unique
from qc_capture_streams import extract, SERVICE_SEEDS
from variant_subset_oracle import verify_fields

def check(kind,stdout,historical=None):
    for lane in extract(kind,stdout):
        for capture in lane:
            if kind=="q":
                for command in capture["commands"]:
                    verify_fields(kind,command["typed_tuple"],command["fields"])
            else:
                for record in capture["records"]:
                    verify_fields(kind,record["typed_payload"],record["fields"])
    if kind=="q":
        check_q(stdout)
    else:
        need(historical is not None,"C historical source required")
        source=json.loads(historical.read_bytes(),object_pairs_hook=unique)
        ids=[(r["seed"],r["kind"]) for r in source["cases"] if r["kind"] in ("estimated","lost")]
        required=[(seed,kind) for seed in SERVICE_SEEDS for kind in ("estimated","lost")]
        need(ids==required,"C historical side-0 duplicate, omission or order drift")
        check_c(stdout,historical_cases(historical))

if __name__=="__main__":
    cli=argparse.ArgumentParser(description=__doc__)
    cli.add_argument("kind",choices=("q","c"))
    cli.add_argument("stdout",type=Path)
    cli.add_argument("--historical-service",type=Path)
    a=cli.parse_args()
    check(a.kind,a.stdout.read_text(encoding="utf-8-sig"),a.historical_service)

