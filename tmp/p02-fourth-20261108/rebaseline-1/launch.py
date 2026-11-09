from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib,json,os,re,shutil,stat,subprocess,sys,time

root=Path.cwd()
old=root/"tmp/p02-fourth-20261108"
out=Path(__file__).resolve().parent
owner="core/battle/operation_private_state.gd"
runner="tests/p02_viewer_events.gd"
engine=Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
cache=".godot/global_script_class_cache.cfg"
uid=".godot/uid_cache.bin"
rows=("p02_headless_adapter","p02_worker_adapter","p02_replay_adapter","detection_rules","battle_flow","placement","i01b_active_replace")
outputs={"p02_headless_adapter":"tmp/p02-first-integration-20261105/attempt1-observations.json",
         "i01b_active_replace":"tmp/i01b-active-replace-20261102/attempt2-observations.json"}
replay="tmp/p02-third-20261108/"
fixtures=["commands","reordered","removed","defaults","one-tick","natural","direct","delegate","late","order","policy","limit","rows","commands-shape"]
known=[".godot/scene_groups_cache.cfg",cache,uid,"project.godot",replay+"oracle.native",*[replay+"matrix/"+x+".json" for x in fixtures]]
dirs=("assets","core","data","hud","input","scenes","scripts","tests","view",".godot/imported")
markers=(b"P02_ADAPTER_PASS",b"P02_WORKER_CHECKS",b"P02_REPLAY_PASS",b"DETECTION_RULES_PASS",b"BATTLE_FLOW_PASS",b"PLACEMENT_PASS",b"I01B_ACTIVE_REPLACE_PASS")
base=json.loads((old/"baseline.json").read_bytes())
excluded=out.relative_to(root).as_posix()+"/"

def read(p): return json.loads(Path(p).read_bytes())
def dump(p,d): Path(p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
def sha(p):
    with Path(p).open("rb") as f: return hashlib.file_digest(f,"sha256").hexdigest()
def info(p): return {"bytes":Path(p).stat().st_size,"sha256":sha(p)}
def git(*args):
    return subprocess.check_output(["git",*args],cwd=root,env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
def live():
    paths={p for p in (git("ls-files","-z")+git("ls-files","--others","--exclude-standard","-z")).decode().split("\0") if p and not p.startswith(excluded)}
    paths.update(p.relative_to(root).as_posix() for p in old.rglob("*") if p.is_file() and not p.relative_to(root).as_posix().startswith(excluded))
    paths.update([cache,uid])
    return paths
def inventory():
    paths=sorted(live())
    with ThreadPoolExecutor(12) as pool:
        return dict(zip(paths,pool.map(lambda p:info(root/p),paths)))
def identity():
    return (git("branch","--show-current").decode().strip()==base["branch"] and git("rev-parse","HEAD").decode().strip()==base["head"]
            and git("ls-files","-s","-z")== (old/"index.raw").read_bytes() and sha(root/".git/index")==base["index_file_sha256"])
def static_verify():
    for item in read(old/"runtime-freeze.json"): assert sha(item["Path"])==item["Hash"].lower()
    original=(old/"owner.before.gd.txt").read_bytes()
    hunk=(old/"owned-hunk.gd.txt").read_bytes()
    current=(root/owner).read_bytes()
    assert current.count(hunk)==1 and current.replace(hunk,b"",1)==original
    for r in base["rows"]:
        if r["path"]==owner: assert info(old/"owner.before.gd.txt")=={k:r[k] for k in ("bytes","sha256")}
    assert identity()

def plain(p):
    st=p.lstat()
    return not p.is_symlink() and not st.st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT and (p.is_dir() or st.st_nlink==1)

def prepare():
    static_verify()
    inv=inventory()
    drift=[r["path"] for r in base["rows"] if inv.get(r["path"])!={k:r[k] for k in ("bytes","sha256")}]
    assert drift==[owner],drift
    new=set(inv)-{r["path"] for r in base["rows"]}
    assert not [p for p in new if p not in (runner,cache,uid) and not p.startswith("tmp/p02-fourth-20261108/")], sorted(new)
    dump(out/"workspace-before.json",inv)
    runtime=[]
    for directory in dirs:
        for current,subdirs,files in os.walk(root/directory):
            assert all(plain(Path(current)/p) for p in subdirs)
            runtime.extend((Path(current)/p).relative_to(root).as_posix() for p in files)
    paths=sorted(set(known+runtime))
    assert all(plain(root/p) for p in paths)
    total=sum((root/p).stat().st_size for p in paths)
    free=shutil.disk_usage(root).free
    dump(out/"copy-budget.json",{"files_per_project":len(paths),"bytes_per_project":total,"free_before":free})
    assert free>2*total+500_000_000
    common={p:info(root/p) for p in paths}
    previous=read(old/"attempt1/freeze.json")["files"]
    assert all(previous.get(str(root/p),r["sha256"])==r["sha256"] for p,r in common.items())
    # Replay's dynamic file paths were frozen separately in its original delivery.
    prior_replay=read(root/replay/"attempt2/freeze.json")["files"]
    assert all(prior_replay[str(root/p)]==r["sha256"] for p,r in common.items() if p.startswith(replay))
    for stage in ("isolated-before","isolated-after"):
        project=out/stage
        project.mkdir()
        inputs={}
        for p in paths:
            source=old/"owner.before.gd.txt" if p==owner and stage=="isolated-before" else root/p
            dest=project/p
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(source,dest)
            assert plain(dest)
            inputs[p]=info(dest)
            assert inputs[p]==(info(source) if p==owner else common[p]),p
        for dest in outputs.values():
            p=project/dest
            assert not p.exists()
            p.parent.mkdir(parents=True,exist_ok=True)
        dump(out/(stage+"-inputs.json"),inputs)
    closure()
    assert inventory()==inv

def closure():
    rels=read(out/"isolated-after-inputs.json")
    targets=["project.godot",cache,*[f"tests/{r}.gd" for r in rows]]
    # Follow global class paths and hard-coded resource paths for the actual
    # scripts/scenes, including resources loaded via UID and .import remaps.
    refs={}
    missing={}
    todo=targets[:]
    while todo:
        p=todo.pop()
        if p in refs: continue
        if p not in rels:
            missing[p]="root"; continue
        if not p.endswith((".gd",".tscn",".tres",".cfg",".godot",".import")): continue
        s=(root/p).read_text(encoding="utf8")
        found=set(re.findall(r'res://([A-Za-z0-9_./+ -]+\.[A-Za-z0-9_]+)(?=["\s])',s))
        if p.startswith("tests/"):
            found.difference_update(outputs.values())
        refs[p]=sorted(found)
        for q in found:
            if q not in rels:
                # Source comments can mention a display-only example. Record it.
                actual=any("res://"+q in line.split("#",1)[0] for line in s.splitlines())
                if actual: missing[q]=p
            else:
                todo.append(q)
                if q+".import" in rels: todo.append(q+".import")
    dump(out/"resource-closure.json",{"roots":targets,"references":refs,"dynamic_replay_inputs":[p for p in known if p.startswith(replay)],
                                      "missing":missing,"excluded_output_paths":outputs})
    assert not missing,missing

def tree(project):
    return {p.relative_to(project).as_posix():info(p) for p in project.rglob("*") if p.is_file()}

def execute(stage,probe_only=False):
    static_verify()
    inv=read(out/"workspace-before.json")
    assert inv==inventory()
    project=out/stage
    evidence=out/(stage+"-run2-logs")
    evidence.mkdir()
    user=evidence/"user"
    roaming=user/"roaming"
    local=user/"local"
    roaming.mkdir(parents=True)
    local.mkdir()
    envkeys={"APPDATA":str(roaming),"LOCALAPPDATA":str(local),"XDG_DATA_HOME":str(roaming)}
    env={**os.environ,**envkeys}
    inputs=read(out/(stage+"-inputs.json"))
    assert tree(project)==inputs
    shared={str(p):info(p) for p in [Path(__file__),out/"verdict.py",out/"probe.gd",engine,
            out/"workspace-before.json",out/"resource-closure.json",out/"isolated-before-inputs.json",out/"isolated-after-inputs.json"]}
    names=["probe",*rows]
    cmds={name:[str(engine),"--headless",*(["--verbose"] if name=="probe" else []),"--path",str(project),"--log-file",str(evidence/(name+".engine.log")),
                "-s",str(out/"probe.gd") if name=="probe" else f"res://tests/{name}.gd"] for name in names}
    dump(evidence/"freeze.json",{"shared":shared,"inputs":inputs,"command_arrays":cmds,"environment":envkeys,
                                "cwd":str(project),"version":(old/"engine-version.txt").read_text().strip()})
    cases=[]
    for name in names:
        started=time.monotonic()
        timeout=False
        try:
            result=subprocess.run(cmds[name],cwd=project,env=env,capture_output=True,timeout=120)
            stdout,stderr,code=result.stdout,result.stderr,result.returncode
        except subprocess.TimeoutExpired as e:
            stdout,stderr,code=e.stdout or b"",e.stderr or b"",None
            timeout=True
        files={}
        for suffix,data in ((".stdout",stdout),(".stderr",stderr)):
            p=evidence/(name+suffix)
            p.write_bytes(data)
            files[p.name]=info(p)
        log=evidence/(name+".engine.log")
        if log.exists(): files[log.name]=info(log)
        record={"label":name,"exit":code,"timeout":timeout,"seconds":round(time.monotonic()-started,3),"files":files}
        if name=="probe":
            lines=[line.removeprefix(b"P02_ISOLATION ") for line in stdout.splitlines() if line.startswith(b"P02_ISOLATION ")]
            observed=json.loads(lines[0]) if len(lines)==1 else {}
            record["probe"]=observed
            resolved=lambda p:Path(p).resolve()
            probe_ok=(code==0 and not stderr and observed.get("guard")==""
                      and resolved(observed.get("res",""))==project
                      and resolved(observed.get("user","")).is_relative_to(user)
                      and observed.get("cache")==inputs[cache]["sha256"] and observed.get("uid")==inputs[uid]["sha256"]
                      and (b"Godot Engine v"+(old/"engine-version.txt").read_text().strip().encode()+b" ") in stdout
                      and observed.get("resources")==["res://core/battle/operation_private_state.gd","res://core/battle/battle_sim.gd",
                            "res://core/battle/detection.gd","res://scenes/FleetBattle3D.tscn"])
            record["passed"]=probe_ok
            if not probe_ok:
                dump(evidence/"results.json",{"cases":[record],"freeze_changes":["probe isolation gate failed"],"processes":1})
                raise SystemExit(f"{stage} isolation gate failed: {observed}")
        else:
            marker=markers[rows.index(name)]
            record["markers"]=[line.decode(errors="replace") for line in stdout.splitlines() if line.startswith(marker)]
            record["diagnostics"]={k:sum(line.startswith(k.encode()+b":") for line in (stdout+b"\n"+stderr).splitlines())
                                   for k in ("SCRIPT ERROR","ERROR","WARNING")}
            record["loaded_resources"]=[line.decode(errors="replace") for line in stdout.splitlines() if b"Loading resource:" in line]
            if name in outputs:
                file=project/outputs[name]
                record["output"]=info(file) if file.exists() else None
            record["passed"]=code==0 and len(record["markers"])==1 and not record["diagnostics"]["SCRIPT ERROR"] and (name not in outputs or record["output"] is not None)
        cases.append(record)
        print(stage,name,code,record["passed"],flush=True)
    final=tree(project)
    drift=sorted({p for p in inputs if final.get(p)!=inputs[p]}| (set(final)-set(inputs)-set(outputs.values())))
    drift.extend(p for p,r in shared.items() if info(p)!=r)
    assert inv==inventory()
    dump(evidence/"results.json",{"cases":cases,"freeze_changes":drift,"processes":len(cases),"user_files":tree(user)})
    return 0 if not drift and all(r["passed"] for r in cases) else 1

if __name__=="__main__":
    if sys.argv[1]=="prepare": prepare()
    else: sys.exit(execute(sys.argv[1]))


