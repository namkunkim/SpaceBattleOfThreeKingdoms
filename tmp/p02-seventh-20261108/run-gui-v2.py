import json,sys,os,pathlib,subprocess,hashlib
d=pathlib.Path(__file__).resolve().parent
r=pathlib.Path.cwd()
stage,lane,label,res,insets=sys.argv[1:]
out=d/f'gui-{stage}-{label}'
out.mkdir()
root=d/f'project-{stage}'
probe=d/'gui-probe.gd'
eng=pathlib.Path('C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe')
exe=eng.with_name(eng.name.replace('_console',''))
files=[eng,exe,probe,r/'scripts/FleetBattle3D.gd',root/'scripts/FleetBattle3D.gd',r/'.godot/global_script_class_cache.cfg',root/'.godot/global_script_class_cache.cfg',d/('after-attempt-02/inputs.json' if stage=='after-02' else f'{stage}-attempt-01/inputs.json'),pathlib.Path(__file__).resolve()]
def hashes():
 return {str(f):hashlib.sha256(f.read_bytes()).hexdigest() for f in files}
before=hashes()
roam=out/'roaming'; local=out/'local'
user=roam/'Godot/app_userdata/SpaceBattleOfThreeKingdoms'
user.mkdir(parents=True);local.mkdir()
(user/'settings.cfg').write_bytes((r/'tmp/p02-sixth-20261108/returning-settings.cfg').read_bytes())
env=dict(APPDATA=str(roam),LOCALAPPDATA=str(local),XDG_DATA_HOME=str(roam),SBTK_SAFE_INSETS=insets)
args=[str(eng),'--path',str(root),'--rendering-method','gl_compatibility','--resolution',res,'--script',str(probe),'--',lane,str(out/'rows.jsonl')]
(out/'command.json').write_text(json.dumps(dict(args=args,env=env,hashes=before),indent=2))
try:
 x=subprocess.run(args,capture_output=True,timeout=135,env={**os.environ,**env})
 rc,stdout,stderr=x.returncode,x.stdout,x.stderr
except subprocess.TimeoutExpired as x:rc,stdout,stderr=None,x.stdout or b'',x.stderr or b''
(out/'stdout').write_bytes(stdout)
(out/'stderr').write_bytes(stderr)
(out/'process.json').write_text(json.dumps(dict(exit=rc,timeout=rc is None,inputs_unchanged=before==hashes()),indent=2))
print(rc)

