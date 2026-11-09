$ErrorActionPreference = 'Stop'
$root = 'C:/WorkSpace/SpaceBattleOfThreeKingdoms'
Set-Location -LiteralPath $root
$before = Get-Content -Raw tmp/i01b-followup-20261028/before.json | ConvertFrom-Json
$allowed = @('core/battle/bundle_layout.gd', 'export_presets.cfg')
$changed = @()
$missing = @()
foreach ($record in $before.files) {
    if (-not (Test-Path -LiteralPath $record.path -PathType Leaf)) { $missing += $record.path }
    elseif ((Get-FileHash -LiteralPath $record.path).Hash.ToLowerInvariant() -ne $record.sha256) { $changed += $record.path }
}
$original = Get-Content -Raw tmp/i01b-followup-20261028/baseline/bundle_layout.gd.txt
$current = Get-Content -Raw core/battle/bundle_layout.gd
$mark = 'static func slots('
$slotsEqual = $original.Substring($original.IndexOf($mark)) -ceq $current.Substring($current.IndexOf($mark))
$new = @(git -c core.quotepath=false ls-files --modified --others --exclude-standard | Where-Object { $_ -notin $before.files.path -and -not $_.StartsWith('tmp/i01b-followup-20261028/') })
$result = [ordered]@{
    head = (git rev-parse HEAD)
    branch = (git branch --show-current)
    before_count = $before.files.Count
    changed_existing = $changed
    unexpected_existing_changes = @($changed | Where-Object { $_ -notin $allowed })
    missing = $missing
    slots_function_identical = $slotsEqual
    new_outside_evidence = $new
    original_data_rules_unchanged = ((Get-FileHash tests/data_rules.gd).Hash.ToLowerInvariant() -eq ($before.files | Where-Object path -eq 'tests/data_rules.gd').sha256)
    original_bundle_test_unchanged = ((Get-FileHash tests/bundle_layout.gd).Hash.ToLowerInvariant() -eq ($before.files | Where-Object path -eq 'tests/bundle_layout.gd').sha256)
}
$result | ConvertTo-Json -Depth 7 | Set-Content tmp/i01b-followup-20261028/preservation-audit.json -Encoding utf8
$result | ConvertTo-Json -Depth 7
if ($result.unexpected_existing_changes.Count -ne 0 -or $missing.Count -ne 0 -or -not $slotsEqual -or -not $result.original_data_rules_unchanged -or -not $result.original_bundle_test_unchanged) { exit 1 }
