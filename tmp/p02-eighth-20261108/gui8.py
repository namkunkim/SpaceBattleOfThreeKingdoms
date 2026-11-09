from stage import *
import sys
stage,lane=sys.argv[1:]
project=T/stage
out=D/'gate-k4'/('gui-'+stage+'-'+lane)
out.mkdir(parents=True)
q=project/('_p02_gate_k4_gui_'+lane+'.gd')
shutil.copyfile(D/'gui8.gd',q)
user=out/'roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms'; user.mkdir(parents=True)
local=out/'local';local.mkdir()
cfg=R/'tmp/p02-sixth-20261108/returning-settings.cfg'
shutil.copyfile(cfg,user/'settings.cfg')
env={'APPDATA':str(out/'roaming'),'LOCALAPPDATA':str(local),'XDG_DATA_HOME':str(out/'roaming'),'SBTK_SAFE_INSETS':'0,0,0,0'}
tag=stage+'-'+lane
exe=E.with_name(E.name.replace('_console',''))
args=[str(exe),'--path',str(project),'--rendering-method','gl_compatibility','--resolution','1280x720','--script','res://'+q.name,'--',tag,str(out)]
dump(out/'command.json',dict(args=args,env=env,probe_sha=sha(q),settings_sha=sha(cfg),engine_sha=sha(exe)))
with (out/'stdout').open('wb') as so, (out/'stderr').open('wb') as se:
 p=subprocess.Popen(args,env={**os.environ,**env},stdout=so,stderr=se)
 dump(out/'pid.json',dict(pid=p.pid,title='P02-8 QA '+tag))
 try:rc=p.wait(timeout=330)
 except subprocess.TimeoutExpired:
  p.kill();p.wait();rc=None
dump(out/'process.json',dict(exit=rc,timeout=rc is None))
