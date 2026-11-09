$ErrorActionPreference='Stop'
$stage='C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01b-p0-20261028-state-inventory'
$root='C:/Users/nk782/.codex/worktrees/i01a-operation-config/SpaceBattleOfThreeKingdoms'
$tool="$stage/tools/scenario/audit_i01b_contract.ps1"
$freezePath="$stage/source-freeze.json"
$freezeHash=(Get-FileHash -LiteralPath $freezePath).Hash.ToLower()
$pwsh=Join-Path $PSHOME 'pwsh.exe'
& $pwsh -NoProfile -File $tool -SourceRoot $root -FreezePath $freezePath -OutputPath "$stage/inventory.json" *> "$stage/logs/normal.log"
$normalExit=$LASTEXITCODE
if($normalExit -ne 0){throw 'Normal runner failed'}
$inv=Get-Content -Raw "$stage/inventory.json"|ConvertFrom-Json
$freeze=Get-Content -Raw $freezePath|ConvertFrom-Json
$checked=0
foreach($file in $inv.files){
    $lines=[System.IO.File]::ReadAllLines((Join-Path $root $file.path))
    $rootLines=@()
    for($n=0;$n -lt $lines.Length;$n++){if($lines[$n] -match '^(static )?var '){$rootLines += $n+1}}
    $reported=@($file.fields | Where-Object owner -eq $file.class_name | ForEach-Object line)
    if(($rootLines -join ',') -cne ($reported -join ',')){throw "Root declarations missing $($file.path)"}
    foreach($field in $file.fields){
        if($lines[$field.line-1] -cne $field.declaration_text){throw 'Raw declaration mismatch'}
        if($field.save_policy -ne 'UNCLASSIFIED'){throw 'Invented save policy'}
        $checked++
    }
}
$state=$inv.files|Where-Object class_name -eq 'BattleState'
$missile=@($state.fields|Where-Object owner -eq 'BattleState.Missile'|ForEach-Object name)
$swarm=@($state.fields|Where-Object owner -eq 'BattleState.Swarm'|ForEach-Object name)
if(($missile -join ',') -cne 'id,pos,target_id,src_id,dmg,v,wob,age,side,dead'){throw 'Missile declarations differ'}
if(($swarm -join ',') -cne 'id,src_id,target_id,life,side,dps,pts,striking'){throw 'Swarm declarations differ'}
if($checked -ne $inv.field_count -or @($inv.unsupported).Count -ne 0){throw 'Inventory counts invalid'}
$shadow="$stage/hash-negative-source"
foreach($f in $freeze.sources){
    $dest=Join-Path $shadow $f.path
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest)|Out-Null
    Copy-Item -LiteralPath (Join-Path $root $f.path) -Destination $dest
}
$mutated=Join-Path $shadow 'core/battle/battle_state.gd'
[System.IO.File]::AppendAllText($mutated,"`n# hash-negative fixture`n",[System.Text.UTF8Encoding]::new($false))
& $pwsh -NoProfile -File $tool -SourceRoot $shadow -FreezePath $freezePath -OutputPath "$stage/hash-negative-output.json" *> "$stage/logs/hash-negative.log"
$negativeExit=$LASTEXITCODE
$negativeText=[System.IO.File]::ReadAllText("$stage/logs/hash-negative.log")
if($negativeExit -eq 0 -or -not $negativeText.Contains('SOURCE_HASH_MISMATCH core/battle/battle_state.gd')){throw 'Hash-negative not rejected'}
if(Test-Path -LiteralPath "$stage/hash-negative-output.json"){throw 'Hash-invalid input published output'}
if((Get-FileHash -LiteralPath $freezePath).Hash.ToLower() -ne $freezeHash){throw 'Independent freeze was changed'}
foreach($f in $freeze.preserved_files){if((Get-FileHash -LiteralPath (Join-Path $root $f.path)).Hash.ToLower() -ne $f.sha256){throw 'Preexisting six changed'}}
$head=git -C $root rev-parse HEAD
if($head -ne $freeze.observed_head){throw 'HEAD changed'}
$result=[ordered]@{normal_exit=$normalExit;normal_marker=(Get-Content "$stage/logs/normal.log" -Tail 1);source_count=@($freeze.sources).Count;modules=$inv.module_count;fields_checked=$checked;unsupported=@($inv.unsupported).Count;nested_missile=$missile.Count;nested_swarm=$swarm.Count;anchors=@($inv.anchors).Count;negative_exit=$negativeExit;negative_reason='SOURCE_HASH_MISMATCH core/battle/battle_state.gd';negative_output_absent=$true;freeze_unchanged=$true;preexisting_six_unchanged=$true;head=$head;freeze_sha256=$freezeHash;inventory_sha256=(Get-FileHash -LiteralPath "$stage/inventory.json").Hash.ToLower()}
[System.IO.File]::WriteAllText("$stage/test-results.json",($result|ConvertTo-Json -Depth 10),[System.Text.UTF8Encoding]::new($false))
Write-Output ($result|ConvertTo-Json -Depth 10)