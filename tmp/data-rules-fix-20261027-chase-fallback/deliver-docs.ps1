$ErrorActionPreference='Stop'
$stage='C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/data-rules-fix-20261027-chase-fallback'
$m=Get-Content -Raw "$stage/docs-manifest.json" | ConvertFrom-Json
Set-Location -LiteralPath $m.target_root
if((git rev-parse HEAD) -ne '8292805143f4561a4f5258d40b7b94adf4ff5802'){throw 'HEAD guard'}
foreach($f in $m.files){
    if($null -eq $f.before_sha256){if(Test-Path -LiteralPath $f.path){throw "Unexpected existing target $($f.path)"}}
    elseif((Get-FileHash -LiteralPath $f.path).Hash.ToLower() -ne $f.before_sha256){throw "Docs before hash $($f.path)"}
    if((Get-FileHash -LiteralPath (Join-Path $stage $f.path)).Hash.ToLower() -ne $f.after_sha256){throw "Docs staged hash $($f.path)"}
}
foreach($f in $m.files){Copy-Item -LiteralPath (Join-Path $stage $f.path) -Destination $f.path}
$code=Get-Content -Raw "$stage/manifest-k2.json" | ConvertFrom-Json
$all=@($code.files)+@($m.files)
foreach($f in $all){if((Get-FileHash -LiteralPath $f.path).Hash.ToLower() -ne $f.after_sha256){throw "Final hash $($f.path)"}}
$check=@(git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check 2>&1)
$checkExit=$LASTEXITCODE
[System.IO.File]::WriteAllLines("$stage/logs/final-diff-check.txt",[string[]]$check)
$before=@(Get-Content "$stage/logs/status-before.txt")
$after=@(git status --porcelain=v1 --untracked-files=all)
[System.IO.File]::WriteAllLines("$stage/logs/status-delivered.txt",$after)
$diff=@(git diff -- $all.path)
[System.IO.File]::WriteAllLines("$stage/logs/delivery.diff",$diff)
$audit=[ordered]@{head=(git rev-parse HEAD);files=@($all | ForEach-Object {[ordered]@{path=$_.path;sha256=(Get-FileHash -LiteralPath $_.path).Hash.ToLower();bytes=(Get-Item -LiteralPath $_.path).Length}});diff_check_exit=$checkExit;tracked_diff_files=@(git -c core.autocrlf=false diff --name-only);status_added=@($after | Where-Object {$_ -notin $before});status_removed=@($before | Where-Object {$_ -notin $after});code_review='Accepted by independent data_rules_review; raw review SHA preserved';committed=$false;pushed=$false}
[System.IO.File]::WriteAllText("$stage/delivery-audit.json",($audit|ConvertTo-Json -Depth 12),[System.Text.UTF8Encoding]::new($false))
Write-Output ($audit|ConvertTo-Json -Depth 12)
if($checkExit -ne 0){exit 1}