[CmdletBinding()]
param(
    [string]$ResultsPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ResultsPath)) {
    $ResultsPath = Join-Path $PSScriptRoot 'results\current.json'
}
$errors = New-Object 'System.Collections.Generic.List[string]'
$scenarioPath = Join-Path $PSScriptRoot 'scenarios.json'

try {
    $catalog = Get-Content -Raw -Encoding UTF8 -LiteralPath $scenarioPath | ConvertFrom-Json
} catch {
    Write-Error "Could not parse scenarios.json: $($_.Exception.Message)"
    exit 1
}

$scenarios = @($catalog.scenarios)
$expectedIds = 1..20 | ForEach-Object { 'E{0:D2}' -f $_ }
$ids = @($scenarios | ForEach-Object { [string]$_.id })
if ((($ids | Sort-Object) -join ',') -ne (($expectedIds | Sort-Object) -join ',')) {
    $errors.Add('Scenario IDs must contain E01 through E20 exactly once.')
}

foreach ($scenario in $scenarios) {
    foreach ($field in @('id', 'prompt', 'fixture', 'invocationModes', 'tools', 'constraints', 'expectedResultType', 'invariants', 'forbiddenSideEffects', 'evaluation')) {
        if (@($scenario.PSObject.Properties.Name) -notcontains $field) {
            $errors.Add("$($scenario.id): missing '$field'")
        }
    }
    if ([string]::IsNullOrWhiteSpace([string]$scenario.prompt)) {
        $errors.Add("$($scenario.id): prompt must not be empty")
    }
    foreach ($listField in @('invocationModes', 'tools', 'constraints', 'invariants', 'forbiddenSideEffects')) {
        if ($scenario.$listField -isnot [System.Array] -or @($scenario.$listField).Count -eq 0) {
            $errors.Add("$($scenario.id): $listField must be a non-empty array")
        }
    }
    $modes = @($scenario.invocationModes | ForEach-Object { [string]$_ })
    foreach ($mode in $modes) {
        if ($mode -notin @('explicit', 'implicit')) {
            $errors.Add("$($scenario.id): invalid invocation mode '$mode'")
        }
    }
    if (@($modes | Select-Object -Unique).Count -ne $modes.Count) {
        $errors.Add("$($scenario.id): invocationModes contains duplicates")
    }
    $fixture = Join-Path $PSScriptRoot ([string]$scenario.fixture)
    if (-not (Test-Path -LiteralPath $fixture)) {
        $errors.Add("$($scenario.id): fixture not found: $fixture")
    }
}

try {
    $results = Get-Content -Raw -Encoding UTF8 -LiteralPath $ResultsPath | ConvertFrom-Json
    $resultItems = @($results.results)
    $resultIds = @($resultItems | ForEach-Object { [string]$_.id })
    if ((($resultIds | Sort-Object) -join ',') -ne (($expectedIds | Sort-Object) -join ',')) {
        $errors.Add('Results must contain E01 through E20 exactly once.')
    }
    foreach ($result in $resultItems) {
        if (([string]$result.status) -notin @('PASS', 'FAIL', 'BLOCKED', 'NOT RUN')) {
            $errors.Add("$($result.id): invalid result status '$($result.status)'")
        }
        if ([string]::IsNullOrWhiteSpace([string]$result.reason)) {
            $errors.Add("$($result.id): result reason must not be empty")
        }
    }
} catch {
    $errors.Add("Could not parse results file '$ResultsPath': $($_.Exception.Message)")
}

if ($errors.Count -gt 0) {
    Write-Error ("Eval validation failed with $($errors.Count) error(s):`n- " + ($errors -join "`n- "))
    exit 1
}

$counts = @($resultItems | Group-Object status | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" })
Write-Host "Eval catalog valid: $($scenarios.Count) scenarios. Results: $($counts -join ', ')."
