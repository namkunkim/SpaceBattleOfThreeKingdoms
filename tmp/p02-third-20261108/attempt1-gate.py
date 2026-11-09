from pathlib import Path
import concurrent.futures as cf, hashlib, json, re, subprocess, sys

root = Path.cwd()
e = root / "tmp/p02-third-20261108"
fixtures = root / "tests/fixtures/p02"
exe = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
cli = "tests/autoresolve.gd"
option = "--operation-replay"
format_id = "p02/restricted-fresh-replay/1"
canonical_cache = "0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1"
cache = root / ".godot/global_script_class_cache.cfg"

def dump(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False)+"\n", encoding="utf8")

def read(path):
    return json.loads(path.read_text(encoding="utf8"))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def frozen(paths):
    return {str(p):sha(p) for p in sorted(set(paths))}

def input_fixture(name):
    return read(fixtures / (name+".json"))

def row(tick=0, side=0, ids=[1], kind="move", target_id=-1, point=[720,510], args={}):
    return dict(tick=tick, side=side, ids=ids, kind=kind, target_id=target_id, point=point, args=args)

def envelope(input, commands):
    return {"format":format_id,"input":input,"commands":commands}

def make_inputs():
    p=e/"matrix"
    p.mkdir()
    records=[]
    def write(label, data, expected=None):
        path=p/(label+".json")
        if isinstance(data, bytes): path.write_bytes(data)
        else: dump(path,data)
        if expected: records.append(dict(label=label,input=path.name,error=list(expected)))
    commands=[row(),row(kind="stop",point=[0,0]),row(tick=2,ids=[9999],kind="attack",target_id=2,point=[0,0])]
    time=input_fixture("timeout-poc")
    data={**time,"max_ticks":3}
    services=input_fixture("worker-services")
    def valid(label,input,cmds):
        write(label,envelope(input,cmds))
    valid("commands",data,commands)
    valid("reordered",data,[commands[1],commands[0],commands[2]])
    valid("removed",data,commands[:2])
    valid("defaults",{**data,"initial_controls":[]},commands)
    valid("one-tick",time,[])
    valid("natural",services,[])
    for mode in ("direct","delegate"):
        valid(mode,{**services,"max_ticks":3,"initial_controls":[mode,mode]},[])
    write("late",envelope(services,[row(17999)]),("replay_unconsumed_command","commands[0].tick"))
    write("malformed",b"{",("invalid_json","input"))
    write("shape",[],("invalid_replay_envelope","$"))
    write("extra",{**envelope(data,[]),"other":0},("invalid_replay_envelope","$"))
    write("format",{**envelope(data,[]),"format":5},("unsupported_replay_format","format"))
    write("input-shape",envelope([],[]),("invalid_container","input"))
    write("commands-shape",envelope(data,{}),("invalid_replay_command","commands"))
    for label,override,code,path in [
        ("definition",{"definition":{}},"unsupported_input_representation","definition"),
        ("checkpoint",{"checkpoint":{}},"unsupported_checkpoint","checkpoint"),
        ("reinforcement",{"profile":{**data["profile"],"reinf":[{}]}},"unsupported_reinforcement","profile.reinf"),
        ("module",{"profile":{**data["profile"],"combat":{"morale":{}}}},"unsupported_module_config","profile.combat"),
        ("product",{"profile":{**data["profile"],"scenario":{"id":"red-cliffs"}}},"unsupported_scenario","profile"),
        ("policy",{"policy":"attack5"},"unsupported_replay_policy","policy"),
        ("bad-policy",{"policy":"unknown"},"unsupported_policy","policy"),
        ("rate",{"hz":20},"unsupported_hz","hz"),
        ("limit",{"max_ticks":18001},"replay_tick_limit","max_ticks"),
        ("zero-limit",{"max_ticks":0},"invalid_integer","max_ticks")]:
        write(label,envelope({**data,**override},[]),(code,"input."+path))
    write("controls-missing",envelope({k:v for k,v in data.items() if k!="initial_controls"},[]),("missing_field","input.initial_controls"))
    write("rows",envelope(data,[row()]*18001),("replay_command_limit","commands"))
    write("bytes",b" "*(16*1024*1024+1),("replay_input_limit","input"))
    write("order",envelope(data,[row(1),row(0)]),("replay_command_order","commands[1].tick"))
    for label,value,code,field in [
        ("row-shape",[],"invalid_replay_command",""),
        ("row-extra",{**row(),"extra":0},"invalid_replay_command",""),
        ("negative-tick",row(-1),"replay_command_tick",".tick"),
        ("last-invalid-tick",row(3),"replay_command_tick",".tick"),
        ("fractional-tick",row(0.5),"invalid_replay_command",".tick"),
        ("string-tick",row("0"),"invalid_replay_command",".tick"),
        ("side",row(side=2),"invalid_replay_command",".side"),
        ("duplicate-id",row(ids=[1,1]),"invalid_replay_command",".ids[1]"),
        ("empty-id",row(ids=[]),"invalid_replay_command",".ids"),
        ("overflow-id",row(ids=[2147483648]),"invalid_replay_command",".ids[0]"),
        ("target",row(target_id=-2),"invalid_replay_command",".target_id"),
        ("string-point",row(point=["1",0]),"invalid_replay_command",".point"),
        ("vector-overflow",row(point=[1e100,0]),"invalid_replay_command",".point"),
        ("kind",row(kind="delegate"),"unsupported_replay_command",".kind"),
        ("nonempty-args",row(args={"on":True}),"invalid_replay_command",".args")]:
        write(label,envelope(data,[value]),(code,"commands[0]"+field))
    dump(p/"rejects.json",records)

def run(stage):
    out=e/stage
    out.mkdir()
    matrix=e/"matrix"
    assert sha(cache)==canonical_cache
    (out/"sentinel.json").write_bytes(b"preserve-existing-output\r\n")
    sentinel_sha=sha(out/"sentinel.json")
    jobs=[]
    def job(label, script=cli, args=(), output=None, error=None):
        cmd=[str(exe),"--headless","--path",str(root),"--log-file",str(out/(label+".engine.log")),"-s",str(script)]
        if args: cmd+=["--",*map(str,args)]
        jobs.append(dict(label=label, command=cmd, error=error, output=str(output) if output else None))
    def cli_job(label, opt, file):
        output=out/(label+".json")
        job(label,args=[opt,file,"--out",output],output=output)
    legacy=out/"legacy.json"
    job("legacy",args=["--runs","1","--policies","none","--out",legacy],output=legacy)
    for mode,opt in (("sync","--operation-input"),("worker","--operation-worker")):
        for fixture in ("poc","services"):
            cli_job(f"{mode}-{fixture}",opt,fixtures/(("worker-" if mode=="worker" else "")+fixture+".json"))
        job(f"{mode}-negative",args=[opt,matrix/"malformed.json","--out",out/(f"{mode}-absent.json")],error=["invalid_json","input"],output=out/(f"{mode}-absent.json"))
    cli_job("sync-worker-services","--operation-input",fixtures/"worker-services.json")
    for flag in ["--no-chain","--no-m9","--wind"]:
        job("legacy"+flag,args=["--operation-input",fixtures/"poc.json",flag,"--out",out/"legacy-absent.json"],error=["unknown_option",flag],output=out/"legacy-absent.json")
    job("world-link","tests/world_link.gd")
    if stage!="before":
        for label in ("commands","repeat","reordered","removed","defaults","one-tick","natural","direct","delegate"):
            name = "commands" if label=="repeat" else label
            fixture=fixtures/("replay-"+name+".json")
            cli_job("replay-"+label,option,fixture if fixture.exists() else matrix/(name+".json"))
        for record in read(matrix/"rejects.json"):
            label=record["label"]
            output=out/(label+"-absent.json")
            job(label,args=[option,matrix/record["input"],"--out",output],error=record["error"],output=output)
        f=matrix/"commands.json"
        o=out/"option-absent.json"
        for label,args,code,path,target in [
            ("mix-sync",["--operation-input",f,option,f,"--out",o],"conflicting_option",option,o),
            ("mix-worker",[option,"--operation-worker"],"conflicting_option",option,o),
            ("unknown",[option,f,"--unknown","--out",o],"unknown_option","--unknown",o),
            ("legacy-option",[option,f,"--runs","1","--out",o],"conflicting_option","--runs",o),
            ("duplicate",[option,f,option,f,"--out",o],"duplicate_option",option,o),
            ("missing-value",[option],"missing_option_value",option,o),
            ("missing-out",[option,f],"missing_option","--out",o),
            ("unreadable",[option,matrix/"absent.json","--out",o],"input_read_failed","input",o),
            ("exists",[option,f,"--out",out/"sentinel.json"],"output_exists","out",None),
            ("output-dir",[option,f,"--out",out],"output_exists","out",None),
            ("output-missing-parent",[option,f,"--out",out/"absent"/"o.json"],"output_parent_missing","out",out/"absent"/"o.json"),
            ("output-before-json",[option,matrix/"malformed.json","--out",out/"sentinel.json"],"output_exists","out",None)]:
            job(label,args=args,error=[code,path],output=target)
        headless=(root/"tests/p02_headless_adapter.gd").read_bytes()
        old=b"res://tmp/p02-first-integration-20261105/attempt1-observations.json"
        assert headless.count(old)==1
        patched=out/"existing-headless.gd"
        patched.write_bytes(headless.replace(old,("res://"+(out/"headless-observation.json").relative_to(root).as_posix()).encode()))
        job("headless-api",patched)
        for label,path in (("worker-api","p02_worker_adapter"),("replay-api","p02_replay_adapter"),("core-rules","core_rules"),("battle-flow","battle_flow")):
            job(label,f"tests/{path}.gd")
    paths=[exe,cache,root/"project.godot",e/"oracle.native",e/"oracle.gd",e/"gate.py",*matrix.glob("*.json")]
    for folder,ext in [("core","*.gd"),("scripts","*.gd"),("tests","*.gd"),("view","*.gd"),("input","*.gd"),("hud","*.gd"),("tools","*.gd"),("data","*.json"),("tests/fixtures","*.json")]:
        paths.extend((root/folder).rglob(ext))
    if stage!="before": paths.append(patched)
    before=frozen(paths)
    dump(out/"freeze.json",dict(jobs=jobs, files=before, version=subprocess.check_output([str(exe),"--version"],text=True).strip()))
    def invoke(record):
        label=record["label"]
        timedout=False
        try:
            result=subprocess.run(record["command"],capture_output=True,timeout=240)
            status,stdout,stderr=result.returncode,result.stdout,result.stderr
        except subprocess.TimeoutExpired as ex:
            status,stdout,stderr,timedout=None,ex.stdout or b"",ex.stderr or b"",True
        (out/(label+".stdout")).write_bytes(stdout)
        (out/(label+".stderr")).write_bytes(stderr)
        output=Path(record["output"]) if record["output"] else None
        digest=sha(output) if output and output.is_file() else None
        flags={marker:len(re.findall(rb"(?m)^"+marker.encode()+b":",stderr+stdout)) for marker in ["SCRIPT ERROR","ERROR","WARNING"]}
        error=record["error"]
        rejects=[json.loads(line.removeprefix(b"OPERATION_REJECT ")) for line in stdout.splitlines() if line.startswith(b"OPERATION_REJECT ")]
        success=status==(1 if error else 0)
        if error: success=success and rejects==[dict(ok=False,error=error[0],path=error[1])] and digest is None
        elif output: success=success and digest is not None
        if label=="world-link":
            success=success and b"WORLD_LINK_PASS" in stdout and flags["SCRIPT ERROR"]==0
        else:
            success=success and not any(flags.values())
        return dict(label=label,exit=status,timeout=timedout,diagnostics=flags,rejects=rejects,output_sha256=digest,pass_process=success)
    with cf.ThreadPoolExecutor(4) as pool:
        results=list(pool.map(invoke,jobs))
    stable=frozen(paths)==before
    comparisons=[]
    def check(label,ok): comparisons.append(dict(label=label,passed=ok))
    check("input/source/class map SHA stable",stable)
    check("existing output bytes",sha(out/"sentinel.json")==sentinel_sha)
    if stage!="before":
        baseline=e/"before"
        for label in ("legacy","sync-poc","sync-services","worker-poc","worker-services","sync-worker-services"):
            source = e/"before-supplemental" if label.startswith("worker") or label=="sync-worker-services" else baseline
            check(label+" byte identical",(out/(label+".json")).is_file() and sha(out/(label+".json"))==sha(source/(label+".json")))
        for label in ("sync-negative","worker-negative","legacy--no-chain","legacy--no-m9","legacy--wind","world-link"):
            check(label+" stdout/stderr unchanged",all((out/(label+"."+ext)).read_bytes()==(baseline/(label+"."+ext)).read_bytes() for ext in ("stdout","stderr")) if label!="world-link" else (out/(label+".stderr")).read_bytes()==(baseline/(label+".stderr")).read_bytes())
        expectation=json.loads((e/"oracle.stdout").read_text(encoding="utf8").split("P02_REPLAY_ORACLE ")[1])
        mapping={"commands":"expected","repeat":"expected","reordered":"reordered","removed":"removed","defaults":"defaults","natural":"natural","one-tick":"one_tick","direct":"direct","delegate":"delegate"}
        for label,oracle in mapping.items():
            got_path=out/("replay-"+label+".json")
            if not got_path.is_file():
                check(label+" output",False)
                continue
            actual=read(got_path)
            expect=expectation[oracle]
            check(label+" oracle",all(actual[k]==expect[k] for k in ("summary","events","event_count")) and actual["meta"]["commands_consumed"]==expect["commands_consumed"])
            name="commands" if label=="repeat" else label
            path=fixtures/("replay-"+name+".json")
            if not path.exists(): path=matrix/(name+".json")
            check(label+" metadata",actual["ok"] and actual["meta"]["executor"]=="replay" and actual["meta"]["replay_format"]==format_id and actual["meta"]["replay_file_sha256"]==sha(path))
        natural=out/"replay-natural.json"
        check("empty replay equals sync services",natural.exists() and all(read(natural)[k]==read(out/"sync-worker-services.json")[k] for k in ("summary","events","event_count")))
        a,b=[out/("replay-"+label+".json") for label in ("commands","repeat")]
        check("repeated exact bytes",a.exists() and b.exists() and sha(a)==sha(b))
    passed=all(r["pass_process"] for r in results) and all(x["passed"] for x in comparisons)
    dump(out/"results.json",dict(stage=stage,passed=passed,processes=len(jobs),cases=results,comparisons=comparisons))
    print(stage,len(jobs),passed,[x for x in results if not x["pass_process"]],[x for x in comparisons if not x["passed"]])
    return passed

if sys.argv[1]=="prepare": make_inputs()
else: sys.exit(0 if run(sys.argv[1]) else 1)
