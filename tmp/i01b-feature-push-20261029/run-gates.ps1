$ErrorActionPreference='Stop'
$taskRoot='C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01b-feature-push-20261029'
$treeRoot="$taskRoot/tree"
$engine='C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe'
$tests=@('core_rules','data_rules','i01_operation_config','i01b_logical_clock','bundle_layout_data','bundle_layout','i01b_runtime_inventory')
$rows=@()
New-Item -ItemType Directory -Path "$taskRoot/logs" -Force | Out-Null
foreach($name in $tests){
 $log="$taskRoot/logs/$name.log"
 $captured="$taskRoot/logs/$name.captured.log"
 $started=[DateTime]::UtcNow.ToString('o')
 $output= @(& $engine --headless --path $treeRoot --script "tests/$name.gd" --log-file $log 2>&1)
 $code=$LASTEXITCODE
 [IO.File]::WriteAllText($captured,($output -join "`n"),[Text.UTF8Encoding]::new($false))
 $rows += [ordered]@{test=$name;exit=$code;started_utc=$started;ended_utc=[DateTime]::UtcNow.ToString('o');log=$log;captured=$captured;output=($output -join "`n")}
 [IO.File]::WriteAllText("$taskRoot/staged-test-results.json",($rows|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
 Write-Output "$name exit=$code"
 if($code -ne 0){exit $code}
}