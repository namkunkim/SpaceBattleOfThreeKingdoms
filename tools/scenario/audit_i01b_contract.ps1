param(
    [Parameter(Mandatory=$true)][string]$SourceRoot,
    [Parameter(Mandatory=$true)][string]$FreezePath,
    [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
# I01b-P0 declaration inventory for this exact source set; not a GDScript parser or save serializer.
$members = @(
    'core/battle/battle_sim.gd','core/battle/battle_state.gd','core/battle/fleet_state.gd',
    'core/battle/rule_set.gd','core/battle/battle_rng.gd','core/battle/tick_clock.gd',
    'core/battle/salvo.gd','core/battle/morale.gd','core/battle/victory.gd','core/battle/terrain.gd',
    'core/battle/ai/commander_ai.gd','core/battle/ai/poc_enemy_ai.gd','core/battle/decisions.gd',
    'core/battle/detection.gd','core/battle/supply.gd','core/battle/stratagem.gd',
    'core/battle/command.gd','core/battle/assault.gd','core/battle/skills.gd'
)
$anchors = @(
    @{path='core/battle/battle_sim.gd';text='func queue(cmd: Dictionary) -> void:';id='queue_entry'},
    @{path='core/battle/battle_sim.gd';text='_queue.append(cmd)';id='queue_pending'},
    @{path='core/battle/battle_sim.gd';text='func issue(cmd: Dictionary) -> void:';id='issue_entry'},
    @{path='core/battle/battle_sim.gd';text='command_log.append(c)';id='issue_or_step_log'},
    @{path='core/battle/battle_sim.gd';text='func step() -> void:';id='step_entry'},
    @{path='core/battle/battle_sim.gd';text='var cmds := _queue';id='step_take_queue'},
    @{path='core/battle/battle_sim.gd';text='st.tick += 1';id='tick_increment'},
    @{path='core/battle/battle_sim.gd';text='if st.over:';id='possible_substep_stop'},
    @{path='core/battle/battle_sim.gd';text='st.clock_ms += sub_ms';id='clock_accumulates'},
    @{path='core/battle/battle_sim.gd';text='f.pos = BattleRules.quant_v(f.pos)';id='post_step_quantization'},
    @{path='core/battle/tick_clock.gd';text='if speed <= 0.0:';id='pause_branch'},
    @{path='scripts/FleetBattle3D.gd';text='f.control = "direct"';id='host_post_init_control'},
    @{path='scripts/FleetBattle3D.gd';text='clock.advance(delta)';id='host_clock_adapter'},
    @{path='core/battle/battle_fingerprint.gd';text='static func of(';id='fingerprint_is_separate'}
)
$expected = @($members + @($anchors.path) | Sort-Object -Unique)
$freeze = Get-Content -Raw -LiteralPath $FreezePath | ConvertFrom-Json
if($freeze.version -ne 'i01b-p0-source-freeze-v1'){throw 'UNSUPPORTED_FREEZE_VERSION'}
if(@($freeze.sources).Count -ne $expected.Count){throw 'SOURCE_SET_MISMATCH'}
foreach($path in $expected){
    $entry = @($freeze.sources | Where-Object path -eq $path)
    if($entry.Count -ne 1){throw "SOURCE_SET_MISMATCH $path"}
    $hash = (Get-FileHash -LiteralPath (Join-Path $SourceRoot $path)).Hash.ToLower()
    if($hash -ne $entry[0].sha256){throw "SOURCE_HASH_MISMATCH $path"}
}
$files = @()
$unsupported = @()
foreach($path in $members){
    $lines = [System.IO.File]::ReadAllLines((Join-Path $SourceRoot $path))
    $owner = ''
    $inner = ''
    $fields = @()
    for($i=0; $i -lt $lines.Length; $i++){
        $line = $lines[$i]
        if($line -match '^class_name\s+(\w+)'){$owner=$Matches[1]}
        if($line -match '^class\s+(\w+):'){
            if($path -ne 'core/battle/battle_state.gd' -or $Matches[1] -notin @('Missile','Swarm')){$unsupported += "$path`:$($i+1) $line"}
            $inner=$Matches[1]
            continue
        }
        # Only the known two inner classes have one-tab data members and no methods.
        if($line -match '^\S' -and $line -notmatch '^#'){$inner=''}
        $member = $line -match '^(?:static )?var\s' -or ($inner -ne '' -and $line -match '^\tvar\s')
        if($member){
            if($line -notmatch '^\s*(?:static )?var\s+(?<field>[A-Za-z_]\w*)(?=\s*(?::=|:|=|#|$))'){$unsupported += "$path`:$($i+1) $line";continue}
            $name=$Matches.field
            $fields += [ordered]@{owner=if($inner -ne ''){"$owner.$inner"}else{$owner};name=$name;line=$i+1;declaration_text=$line;value_status='source_text_only_not_runtime_default';save_policy='UNCLASSIFIED'}
        } elseif(($line -match '^.*\bvar\b') -and ($line -match '^@' -or ($inner -ne '' -and $line -match '^\t@'))){
            $unsupported += "$path`:$($i+1) $line"
        }
    }
    if($owner -eq ''){throw "CLASS_NAME_MISSING $path"}
    $files += [ordered]@{path=$path;class_name=$owner;sha256=(Get-FileHash -LiteralPath (Join-Path $SourceRoot $path)).Hash.ToLower();fields=@($fields)}
}
$observed = @()
foreach($a in $anchors){
    $lines = [System.IO.File]::ReadAllLines((Join-Path $SourceRoot $a.path))
    $found=@()
    for($i=0; $i -lt $lines.Length; $i++){if($lines[$i].Contains($a.text)){$found += [ordered]@{line=$i+1;text=$lines[$i]}}}
    if($found.Count -eq 0){throw "ANCHOR_MISSING $($a.id)"}
    $observed += [ordered]@{id=$a.id;path=$a.path;matches=$found;status='source_observation_not_runtime_gate'}
}
$result=[ordered]@{
    version='i01b-p0-inventory-v1';baseline_head=$freeze.observed_head;
    freeze_sha256=(Get-FileHash -LiteralPath $FreezePath).Hash.ToLower();
    status=if($unsupported.Count -eq 0){'DECLARATIONS_OBSERVED'}else{'UNSUPPORTED_DECLARATION'};
    module_count=$files.Count;field_count=@($files.fields).Count;files=$files;anchors=$observed;unsupported=$unsupported;
    limitations=@('Exact frozen sources only; function locals excluded; two known nested classes only',
        'Raw declaration line may start a multiline initializer; initializer is never evaluated',
        'Dynamic Dictionary contents, units, reconstruction/save policy and native object state are not inventoried',
        'No runtime, adapter, checkpoint, suffix, product geometry or complete snapshot contract is validated');
    readiness=@{original_A04='NOT_READY';original_A05='NOT_READY';original_A06='NOT_READY'}
}
[System.IO.File]::WriteAllText($OutputPath,($result|ConvertTo-Json -Depth 30),[System.Text.UTF8Encoding]::new($false))
if($unsupported.Count -gt 0){throw ('UNSUPPORTED_DECLARATION ' + ($unsupported -join ' | '))}
Write-Output "I01B_P0_INVENTORY_PASS modules=$($files.Count) fields=$($result.field_count) anchors=$($observed.Count)"