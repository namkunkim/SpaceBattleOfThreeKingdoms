from pathlib import Path
import hashlib, json, subprocess
root=Path.cwd()
out=root/'tmp/p02-next-20261107'
def digest(b): return hashlib.sha256(b).hexdigest()
def save(name, x): (out/name).write_text(json.dumps(x,ensure_ascii=False,indent=2),encoding='utf-8')
baseline=json.loads((out/'baseline-files.json').read_text(encoding='utf-8'))
owned={'scripts/world/auto_resolver.gd','tests/autoresolve.gd'}
concurrent={f'tmp/p03-state-checkpoint-20261105/{n}.py' for n in ['inventory','run_gate','test_inventory']}
allowed_new={'tests/p02_worker_adapter.gd',*(f'tests/fixtures/p02/worker-{n}.json' for n in ['poc','services','timeout-poc'])}
changes, preserved, absent, owned_rows = [],0,[],[]
for row in baseline:
 name=row['path']
 path=root/name
 if not path.exists():
  absent.append(name)
  continue
 b=path.read_bytes()
 current={'bytes':len(b),'sha256':digest(b)}
 if current=={k:row[k] for k in current}:
  preserved+=1
  continue
 record={'baseline':row,'current':current}
 if name in owned:
  original=(out/'before'/f'{path.name}.txt').read_bytes()
  record['original_preserved']=len(original)==row['bytes'] and digest(original)==row['sha256']
  owned_rows.append(record)
 else:
  record['ownership']='P03 concurrent thread' if name in concurrent else 'unconfirmed'
  changes.append(record)
commands={'head':['rev-parse','HEAD'],'branch':['branch','--show-current'],'index':['diff','--cached','--name-status'],
          'index_tree':['ls-files','--stage','-z'],'diff-check':['diff','--check']}
contexts={}
for name,args in commands.items():
 p=subprocess.run(['git',*args],capture_output=True)
 (out/f'post-{name}.stdout').write_bytes(p.stdout)
 (out/f'post-{name}.stderr').write_bytes(p.stderr)
 contexts[name]={'exit':p.returncode,'stdout_equal':p.stdout==(out/f'{name}.stdout').read_bytes(),
                  'stderr_equal':p.stderr==(out/f'{name}.stderr').read_bytes()}
s=subprocess.run(['git','ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True)
listed={x.decode('utf-8') for x in s.stdout.split(b'\0') if x}
baseline_paths={row['path'] for row in baseline}
extra=sorted(x for x in listed-baseline_paths if not x.startswith('tmp/p02-next-20261107/'))
new_confirmed=[x for x in extra if x in allowed_new]
new_other=[x for x in extra if x not in allowed_new]
p=subprocess.run(['git','diff','--check','--',*sorted(owned)],capture_output=True)
(out/'post-owned-diff-check.stdout').write_bytes(p.stdout)
(out/'post-owned-diff-check.stderr').write_bytes(p.stderr)
save('preservation.json',{'baseline':len(baseline),'byte_exact_preserved':preserved,'owned':owned_rows,'non_owned_changes':changes,'missing':absent,'new_allowed':new_confirmed,'new_concurrent_p03':[x for x in new_other if x.startswith(('tmp/p03-state-checkpoint-20261105/','tmp/p03-command-suffix-20261107/'))],'new_other':[x for x in new_other if not x.startswith(('tmp/p03-state-checkpoint-20261105/','tmp/p03-command-suffix-20261107/'))],'context':contexts,'owned_diff_check_exit':p.returncode})
print(len(baseline),preserved,'changes',len(changes),'missing',len(absent),'new_other_count',len(new_other),'contexts',contexts)
