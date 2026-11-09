from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from launch import root,old,out,owner,info,read,dump,identity,outputs

stages=("isolated-before","isolated-after")
frozen={stage:read(out/(stage+"-run2-logs")/"freeze.json") for stage in stages}
reports={stage:read(out/(stage+"-run2-logs")/"results.json") for stage in stages}
after=frozen["isolated-after"]["inputs"]
with ThreadPoolExecutor(12) as pool:
    source_drift=[name for name,passed in zip(after,pool.map(lambda p:info(root/p)==after[p],after)) if not passed]
resources={}
for stage in stages:
    logs=out/(stage+"-run2-logs")
    report=reports[stage]
    project=Path(frozen[stage]["cwd"])
    probe=report["cases"][0]["probe"]
    loaded=[line.split(" remapped:",1)[0].removeprefix("Loading resource: ") for line in (logs/"probe.stdout").read_text().splitlines() if line.startswith("Loading resource: res://")]
    resources[stage]={"actual_res":probe["res"],"actual_user":probe["user"],"loaded":loaded,
                      "loaded_all_in_manifest":all(p[6:] in after for p in loaded),
                      "artifacts":report["user_files"],
                      "fixed_outputs":{k:{"path":str(project/p),**info(project/p)} for k,p in outputs.items()}}
result={"live_source_vs_copied_after_manifest_drift":source_drift,
        "first_and_last_shared_freeze_equal":frozen[stages[0]]["shared"]==frozen[stages[1]]["shared"],
        "identity_after_diff_check":identity(),
        "actual_new_processes":{"regressions":14,"probes":3,"failed_probe_exit":read(out/"isolated-before-logs/results.json")["cases"][0]["exit"]},
        "resources":resources}
result["passed"]=not source_drift and result["first_and_last_shared_freeze_equal"] and result["identity_after_diff_check"] and all(r["loaded_all_in_manifest"] for r in resources.values())
dump(out/"additional-protection.json",result)
print(result["passed"],source_drift)
