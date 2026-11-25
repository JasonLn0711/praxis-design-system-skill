[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$Skills,
    [string]$Destination = (Join-Path $env:USERPROFILE '.codex\skills'),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceRoot = Join-Path $repoRoot 'skills'
$modulePath = Join-Path $repoRoot 'scripts\SkillPack.Common.psm1'

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Shared module not found: $modulePath"
}
Import-Module -Name $modulePath -Force

$manifest = Read-SkillPackManifest -RepoRoot $repoRoot
$manifestErrors = @(Get-SkillPackManifestErrors -Manifest $manifest -SkillsRoot $sourceRoot)
if ($manifestErrors.Count -gt 0) {
    throw ("Installation preflight failed:`n- " + ($manifestErrors -join "`n- "))
}

$requested = New-Object 'System.Collections.Generic.List[string]'
$seenRequested = @{}
foreach ($value in @($Skills)) {
    foreach ($part in @([string]$value -split ',')) {
        $name = $part.Trim()
        if ($name -and -not $seenRequested.ContainsKey($name)) {
            $seenRequested[$name] = $true
            $requested.Add($name)
        }
    }
}

if ($requested.Count -eq 0) {
    foreach ($entry in @($manifest.skills)) {
        $name = [string]$entry.name
        if (-not $seenRequested.ContainsKey($name)) {
            $seenRequested[$name] = $true
            $requested.Add($name)
        }
    }
}

# Resolve and validate the complete graph before creating or changing the destination.
$selection = Get-SkillPackDependencyOrder -Manifest $manifest -Requested @($requested)

$sources = @{}
foreach ($name in @($selection.InstallOrder)) {
    $source = Join-Path $sourceRoot $name
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Installation preflight failed: source directory not found for '$name': $source"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
        throw "Installation preflight failed: SKILL.md not found for '$name'."
    }
    $sources[$name] = $source
}

$fullDestination = Get-SkillPackFullPath -Path $Destination -BasePath (Get-Location).Path
foreach ($name in @($selection.InstallOrder)) {
    $target = Get-SkillPackFullPath -Path (Join-Path $fullDestination $name)
    if (-not (Test-SkillPackChildPath -Path $target -Root $fullDestination)) {
        throw "Installation preflight failed: target escapes destination for '$name': $target"
    }
}

Write-Host "Requested: $(@($selection.Requested) -join ', ')"
if (@($selection.AddedDependencies).Count -gt 0) {
    Write-Host "Added dependencies: $(@($selection.AddedDependencies) -join ', ')"
} else {
    Write-Host 'Added dependencies: (none)'
}

if (-not (Test-Path -LiteralPath $fullDestination -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($fullDestination, 'Create installation destination')) {
        New-Item -ItemType Directory -Path $fullDestination -Force | Out-Null
    }
}

foreach ($name in @($selection.InstallOrder)) {
    $source = $sources[$name]
    $target = Join-Path $fullDestination $name

    if (Test-Path -LiteralPath $target) {
        if (-not $Force) {
            Write-Warning "Skipped $name because it already exists. Use -Force to replace it."
            continue
        }

        $resolvedTarget = (Resolve-Path -LiteralPath $target).Path
        if (-not (Test-SkillPackChildPath -Path $resolvedTarget -Root $fullDestination)) {
            throw "Refusing to replace path outside destination: $resolvedTarget"
        }

        if ($PSCmdlet.ShouldProcess($resolvedTarget, "Replace skill '$name'")) {
            Remove-Item -LiteralPath $resolvedTarget -Recurse -Force
            Copy-Item -LiteralPath $source -Destination $target -Recurse
            Write-Host "Installed $name -> $target"
        }
        continue
    }

    if ($PSCmdlet.ShouldProcess($target, "Install skill '$name'")) {
        Copy-Item -LiteralPath $source -Destination $target -Recurse
        Write-Host "Installed $name -> $target"
    }
}

Write-Host 'Restart Codex to load the installed skills.'
