from pathlib import Path
import json,re,subprocess,sys
from launch import root,old,out,owner,runner,rows,outputs,info,read,dump,inventory,identity,tree,static_verify

def stage_dir(stage):
    return out/(stage+"-run2-logs") if stage.startswith("isolated-") else old/stage

def verify_stage(stage):
    directory=stage_dir(stage)
    data=read(directory/"results.json")
    freeze=read(directory/"freeze.json")
    issues=list(data["freeze_changes"])
    if stage.startswith("isolated-"):
        for name,expected in freeze["shared"].items():
            if info(name)!=expected: issues.append(name)
        project=Path(freeze["cwd"])
        actual=tree(project)
        for name,expected in freeze["inputs"].items():
            if actual.get(name)!=expected: issues.append(name)
        issues.extend(sorted(set(actual)-set(freeze["inputs"])-set(outputs.values())))
        for case in data["cases"]:
            for name,expected in case["files"].items():
                if info(directory/name)!=expected: issues.append(name)
            if case["label"] in outputs and info(project/outputs[case["label"]])!=case["output"]: issues.append(case["label"])
        if not data["cases"][0].get("passed"): issues.append("probe")
    else:
        for name,expected in freeze["files"].items():
            location=Path(name)
            if location==root/owner and stage!="attempt1":
                location=old/"owner.before.gd.txt"
            if location==old/"gate.py" and stage=="before":
                location=out/"legacy-before-gate.py.txt"
            if not location.is_file() or info(location)["sha256"]!=expected: issues.append(name)
    return {"stage":stage,"results":info(directory/"results.json"),"freeze":info(directory/"freeze.json"),
            "issues":issues,"passed":not issues}

def case(stage,label):
    d=stage_dir(stage)
    data=next(item for item in read(d/"results.json")["cases"] if item["label"]==label)
    files={suffix:info(d/(label+suffix)) for suffix in (".stdout",".stderr",".engine.log")}
    return {"stage":stage,"record":data,"files":files}

def plan(before_reg="isolated-before"):
    cases={name:[("before",name),("attempt1",name)] for name in ("sync","worker","replay","unsupported")}
    cases["world_link"]=[("baseline-world","world_link"),("attempt1","world_link")]
    cases["viewer"]=[("attempt1","viewer")]
    for name in rows: cases[name]=[(before_reg,name),("isolated-after",name),("attempt1",name)] if before_reg else [("isolated-after",name),("attempt1",name)]
    return cases

def check_structure(selection):
    mandatory=plan()
    issues=[]
    if set(selection)!=set(mandatory): issues.append("case names")
    for name,sources in mandatory.items():
        provided=selection.get(name,[])
        if provided!=sources: issues.append(name+" required source set")
    stages={}
    for provided in selection.values():
        for stage,_ in provided:
            if stage not in stages: stages[stage]=verify_stage(stage)
    return {"references":stages,"missing_or_wrong_case_sources":issues,
            "passed":not issues and all(s["passed"] for s in stages.values())}

def strict_stderr(stage,label):
    return (stage_dir(stage)/(label+".stderr")).read_bytes()

def historical_battleflow(blob):
    lines=(root/"tmp/i01b-followup-20261028/logs/battle_flow-output.log").read_bytes().splitlines()
    return blob.splitlines()==lines[lines.index(b"BATTLE_FLOW_PASS")+1:]

def main():
    static_verify()
    inv=read(out/"workspace-before.json")
    workspace_same=inventory()==inv and identity()
    dump(out/"workspace-after.json",inventory())
    selections={"positive":plan(),"omitted_isolated_before":plan(None),"injected_old_dirty_baseline":plan("baseline-regressions")}
    checks={name:check_structure(selection) for name,selection in selections.items()}
    comparisons={}
    for name,refs in selections["positive"].items():
        actual=[case(*r) for r in refs]
        records=[item["record"] for item in actual]
        if name in rows:
            before,after,legacy=records
            stderr=[strict_stderr(stage,name) for stage,_ in refs]
            historical= [historical_battleflow(blob) for blob in stderr] if name=="battle_flow" else []
            # Frozen prior behavior allows the exact prior BattleFlow 153/18
            # suffix or direct byte equality. No new count/shape allowlist.
            same_stderr=(stderr[0]==stderr[1]==stderr[2] or
                         (name=="battle_flow" and all(s==stderr[0] or h for s,h in zip(stderr,historical))))
            markers=before["markers"]==after["markers"]
            if name=="p02_worker_adapter":
                markers=(re.sub(r" running_frames_observed=\d+$","",before["markers"][0])==
                         re.sub(r" running_frames_observed=\d+$","",after["markers"][0]))
            prior_stdout=(stage_dir("attempt1")/(name+".stdout")).read_bytes()
            fixed_marker=re.sub(r" running_frames_observed=\d+$","",after["markers"][0])
            legacy_marker=any(line.startswith(fixed_marker.encode()) for line in prior_stdout.splitlines())
            output_equal=name not in outputs or before["output"]==after["output"]
            comparisons[name]={"actual":actual,"markers_match":markers,"legacy_marker_matches":legacy_marker,
                               "stdout_byte_matches_before_after":actual[0]["files"][".stdout"]==actual[1]["files"][".stdout"],
                               "output_byte_matches":output_equal,"stderr_byte_matches":stderr[0]==stderr[1],
                               "historical_battleflow_stderr_matches":historical,
                               "passed":all(r.get("passed",r.get("pass_process")) and r["exit"]==0 for r in records)
                               and same_stderr and markers and legacy_marker and output_equal and
                               all(r["diagnostics"]==legacy["diagnostics"] for r in records)}
        else:
            passed=all(r["pass_process"] for r in records)
            if name=="viewer":
                stdout=(stage_dir("attempt1")/"viewer.stdout").read_bytes()
                passed &= re.findall(rb"^VIEWER_ROW (E\d\d) PASS ",stdout,re.M)==[f"E{i:02}".encode() for i in range(1,15)]
            elif name=="world_link":
                passed &= records[0]["exit"]==records[1]["exit"]==0 and strict_stderr("baseline-world",name)==strict_stderr("attempt1",name)
            else:
                passed &= all(records[0][key]==records[1][key] for key in ("exit","timeout","rejects","output_sha256"))
                if name!="unsupported":
                    passed &= all(info(stage_dir(stage)/(label+".json"))["sha256"]==record["output_sha256"] for (stage,label),record in zip(refs,records))
                else:
                    passed &= all(not (stage_dir(stage)/(label+".json")).exists() for stage,label in refs)
            comparisons[name]={"actual":actual,"passed":passed}
    relocation=(old/"attempt1/headless-output-relocation.gd").read_bytes()
    relocated=b"res://tmp/p02-fourth-20261108/attempt1/headless-observation.json"
    oldrel=b"res://"+outputs["p02_headless_adapter"].encode()
    relocation_ok=relocation.count(relocated)==1 and relocation.replace(relocated,oldrel)==(root/"tests/p02_headless_adapter.gd").read_bytes()
    diff=subprocess.run(["git","diff","--check"],cwd=root,capture_output=True)
    (out/"diff-check.stdout").write_bytes(diff.stdout)
    (out/"diff-check.stderr").write_bytes(diff.stderr)
    diff_ok=diff.returncode==2 and diff.stdout.splitlines()==(old/"diff-check-before.stdout").read_bytes().splitlines()
    before_inputs=read(out/"isolated-before-inputs.json")
    after_inputs=read(out/"isolated-after-inputs.json")
    pair_ok=set(before_inputs)==set(after_inputs) and [k for k in before_inputs if before_inputs[k]!=after_inputs[k]]==[owner]
    dirty_failed=not checks["injected_old_dirty_baseline"]["passed"] and bool(checks["injected_old_dirty_baseline"]["references"]["baseline-regressions"]["issues"])
    omitted_failed=not checks["omitted_isolated_before"]["passed"] and "isolated-before" not in checks["omitted_isolated_before"]["references"]
    dump(out/"negative-verdicts.json",{k:v for k,v in checks.items() if k!="positive"})
    result={"base_process_denominator":17,"new_regression_processes":14,"new_probe_processes":2,
            "workspace_unchanged":workspace_same,"isolated_input_pair_owner_only":pair_ok,"legacy_headless_reversal_exact":relocation_ok,
            "diff_check_actual_exit":diff.returncode,"diff_check_baseline_match":diff_ok,"stage_gate":checks["positive"],
            "negative_dirty_reference_rejected":dirty_failed,"negative_missing_before_rejected":omitted_failed,
            "comparisons":comparisons}
    result["passed"]=all((workspace_same,pair_ok,relocation_ok,diff_ok,checks["positive"]["passed"],dirty_failed,omitted_failed,
                          all(item["passed"] for item in comparisons.values())))
    dump(out/"verdict.json",result)
    print(result["passed"],{k:v["passed"] for k,v in comparisons.items()},checks["positive"])
    return 0 if result["passed"] else 1

if __name__=="__main__": sys.exit(main())

