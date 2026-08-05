[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TimelineJson,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [string]$OutputRoot = '.acceptance',
    [long]$MinimumInputBytes = 100MB,
    [switch]$AllowInputInsideRepository
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Require-Command([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) { throw "Required command not found: $Name" }
    $command.Source
}

$flutter = Require-Command 'flutter'
$git = Require-Command 'git'
$repo = [System.IO.Path]::GetFullPath($RepoRoot)
$input = [System.IO.Path]::GetFullPath($TimelineJson)
if (-not (Test-Path -LiteralPath $input -PathType Leaf)) { throw 'Timeline JSON was not found.' }
$repoPrefix = $repo.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if (-not $AllowInputInsideRepository -and $input.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'The private Timeline input must remain outside the repository. Move it to a private local directory.'
}
$inputBytes = (Get-Item -LiteralPath $input).Length
if ($inputBytes -lt $MinimumInputBytes) {
    throw "Input is $inputBytes bytes; expected at least $MinimumInputBytes bytes for the large-file acceptance."
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDirectory = [System.IO.Path]::GetFullPath((Join-Path $repo "$OutputRoot/kurashilog-private-timeline-$stamp"))
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null
$reportJson = Join-Path $runDirectory 'report.json'
$testLog = Join-Path $runDirectory 'flutter-test.log'
$reportMarkdown = Join-Path $runDirectory 'report.md'
$lockRoot = Join-Path $repo $OutputRoot
New-Item -ItemType Directory -Path $lockRoot -Force | Out-Null
$lockPath = Join-Path $lockRoot '.local-acceptance.lock'
$lock = $null

try {
    try {
        $lock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    } catch {
        throw "Another local acceptance run appears active: $lockPath"
    }

    Push-Location $repo
    try {
        $arguments = @(
            'test',
            'tool/acceptance/private_timeline_acceptance_test.dart',
            "--dart-define=KURASHILOG_PRIVATE_TIMELINE=$input",
            "--dart-define=KURASHILOG_ACCEPTANCE_REPORT=$reportJson"
        )
        $output = @(& $flutter @arguments 2>&1 | ForEach-Object { "$_" })
        $exitCode = $LASTEXITCODE
        $safeOutput = $output | ForEach-Object { $_.Replace($input, '<PRIVATE_TIMELINE_PATH>') }
        $safeOutput | Set-Content -LiteralPath $testLog -Encoding utf8
        if ($exitCode -ne 0) { throw "Flutter acceptance test failed with exit code $exitCode. See $testLog" }
    } finally { Pop-Location }

    if (-not (Test-Path -LiteralPath $reportJson)) { throw 'The acceptance harness did not create report.json.' }
    $report = Get-Content -LiteralPath $reportJson -Raw | ConvertFrom-Json -Depth 50
    if ($report.result -ne 'PASS') { throw "Acceptance report result was $($report.result)." }
    if ($report.inputBytes -ne $inputBytes) { throw 'Reported input byte count does not match the selected file.' }
    if ($report.reimportAddedVisits -ne 0 -or $report.reimportAddedMovements -ne 0) { throw 'Reimport was not idempotent.' }

    $head = (& $git -C $repo rev-parse HEAD).Trim()
    $lines = @(
        '# kurashilog private Timeline acceptance',
        '',
        '- Result: **PASS**',
        "- Repository HEAD: $head",
        "- Input bytes: $($report.inputBytes)",
        "- Schema: $($report.schemaType)",
        "- Preview: $($report.previewMilliseconds) ms",
        "- Import: $($report.importMilliseconds) ms",
        "- Reimport: $($report.reimportMilliseconds) ms",
        "- Peak RSS: $($report.peakRssBytes) bytes",
        "- Visits: $($report.visitCount)",
        "- Movements: $($report.movementCount)",
        "- Path points: $($report.pathPointCount)",
        "- First import additions: visits=$($report.addedVisits), movements=$($report.addedMovements)",
        '- Reimport additions: visits=0, movements=0',
        '',
        '## Privacy',
        '',
        '- Private path: not included',
        '- File hash: not included',
        '- Coordinates/place names/source timestamps: not included',
        '- Source JSON: not copied',
        '',
        "Machine-readable report: $reportJson",
        "Redacted test log: $testLog"
    )
    $lines | Set-Content -LiteralPath $reportMarkdown -Encoding utf8
    Write-Host 'Result: PASS'
    Write-Host "Report: $reportMarkdown"
} finally {
    if ($lock) { $lock.Dispose() }
    Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
}
