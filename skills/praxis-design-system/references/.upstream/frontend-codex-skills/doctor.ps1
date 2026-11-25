[CmdletBinding()]
param(
    [string[]]$SkillRoots,
    [switch]$Json,
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function New-DoctorResult {
    param([string]$Version)

    return [ordered]@{
        version      = $Version
        roots        = @()
        summary      = [ordered]@{
            healthy             = $false
            rootsScanned        = 0
            skillsScanned       = 0
            duplicateNames      = 0
            driftedCopies       = 0
            dependencyIssues    = 0
            referenceIssues     = 0
            configurationErrors = 0
        }
        duplicates   = @()
        drift        = @()
        dependencies = @()
        references   = @()
        configuration = @()
    }
}

function Complete-Doctor {
    param(
        [System.Collections.IDictionary]$Result,
        [int]$ExitCode
    )

    if ($Json) {
        $Result | ConvertTo-Json -Depth 10
    } else {
        if ($ExitCode -eq 2) {
            Write-Host 'Skill pack doctor could not run because the configuration is invalid.' -ForegroundColor Red
        } elseif ($ExitCode -eq 1) {
            Write-Host 'Skill pack doctor found problems.' -ForegroundColor Yellow
        } else {
            Write-Host 'Skill pack doctor: healthy.' -ForegroundColor Green
        }

        Write-Host "Roots scanned: $($Result.summary.rootsScanned)"
        Write-Host "Skills scanned: $($Result.summary.skillsScanned)"
        Write-Host "Duplicate names: $($Result.summary.duplicateNames)"
        Write-Host "Drifted copies: $($Result.summary.driftedCopies)"
        Write-Host "Dependency issues: $($Result.summary.dependencyIssues)"
        Write-Host "Reference issues: $($Result.summary.referenceIssues)"

        foreach ($issue in @($Result.configuration)) {
            Write-Host "CONFIG: $($issue.message)" -ForegroundColor Red
        }
        foreach ($duplicate in @($Result.duplicates)) {
            Write-Host "DUPLICATE: $($duplicate.name)" -ForegroundColor Yellow
            foreach ($path in @($duplicate.paths)) {
                Write-Host "  $path"
            }
        }
        foreach ($item in @($Result.drift)) {
            Write-Host "DRIFT: $($item.name) at $($item.path)" -ForegroundColor Yellow
            if (@($item.missing).Count -gt 0) { Write-Host "  Missing: $(@($item.missing) -join ', ')" }
            if (@($item.extra).Count -gt 0) { Write-Host "  Extra: $(@($item.extra) -join ', ')" }
            if (@($item.changed).Count -gt 0) { Write-Host "  Changed: $(@($item.changed) -join ', ')" }
        }
        foreach ($item in @($Result.dependencies)) {
            Write-Host "DEPENDENCY: $($item.name) at $($item.path) is missing $($item.missing -join ', ')" -ForegroundColor Yellow
        }
        foreach ($item in @($Result.references)) {
            Write-Host "REFERENCE: $($item.name) $($item.type) '$($item.reference)' in $($item.source)" -ForegroundColor Yellow
        }
    }

    exit $ExitCode
}

$result = New-DoctorResult -Version $null
$configurationErrors = New-Object 'System.Collections.Generic.List[string]'

try {
    $fullRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
    $modulePath = Join-Path $fullRepoRoot 'scripts\SkillPack.Common.psm1'
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw "Shared module not found: $modulePath"
    }
    Import-Module -Name $modulePath -Force

    $manifest = Read-SkillPackManifest -RepoRoot $fullRepoRoot
    $result.version = [string]$manifest.version
    $repoSkillsRoot = Join-Path $fullRepoRoot 'skills'
    foreach ($manifestError in @(Get-SkillPackManifestErrors -Manifest $manifest -SkillsRoot $repoSkillsRoot)) {
        $configurationErrors.Add($manifestError)
    }
} catch {
    $configurationErrors.Add($_.Exception.Message)
}

if ($configurationErrors.Count -gt 0) {
    $result.configuration = @($configurationErrors | ForEach-Object { [ordered]@{ message = $_ } })
    $result.summary.configurationErrors = $configurationErrors.Count
    Complete-Doctor -Result $result -ExitCode 2
}

$candidateRoots = New-Object 'System.Collections.Generic.List[string]'
$seenRoots = @{}
if (@($SkillRoots).Count -gt 0) {
    foreach ($value in @($SkillRoots)) {
        foreach ($part in @([string]$value -split ',')) {
            if ([string]::IsNullOrWhiteSpace($part)) {
                continue
            }
            try {
                $root = Get-SkillPackFullPath -Path $part.Trim() -BasePath (Get-Location).Path
                if (-not (Test-Path -LiteralPath $root -PathType Container)) {
                    $configurationErrors.Add("Skill root does not exist: $root")
                } elseif (-not $seenRoots.ContainsKey($root)) {
                    $seenRoots[$root] = $true
                    $candidateRoots.Add($root)
                }
            } catch {
                $configurationErrors.Add("Invalid skill root '$part': $($_.Exception.Message)")
            }
        }
    }
} else {
    foreach ($defaultRoot in @(
        (Join-Path $env:USERPROFILE '.codex\skills'),
        (Join-Path $env:USERPROFILE '.agents\skills')
    )) {
        if (Test-Path -LiteralPath $defaultRoot -PathType Container) {
            $root = (Resolve-Path -LiteralPath $defaultRoot).Path
            if (-not $seenRoots.ContainsKey($root)) {
                $seenRoots[$root] = $true
                $candidateRoots.Add($root)
            }
        }
    }
}

if ($candidateRoots.Count -eq 0 -and $configurationErrors.Count -eq 0) {
    $configurationErrors.Add('No existing skill roots were found to scan.')
}

if ($configurationErrors.Count -gt 0) {
    $result.roots = $candidateRoots.ToArray()
    $result.configuration = @($configurationErrors | ForEach-Object { [ordered]@{ message = $_ } })
    $result.summary.configurationErrors = $configurationErrors.Count
    Complete-Doctor -Result $result -ExitCode 2
}

$result.roots = $candidateRoots.ToArray()
$result.summary.rootsScanned = $candidateRoots.Count

$installed = New-Object 'System.Collections.Generic.List[object]'
foreach ($root in $candidateRoots) {
    try {
        foreach ($skillFile in @(Get-ChildItem -LiteralPath $root -Filter 'SKILL.md' -File -Recurse -ErrorAction Stop | Sort-Object FullName)) {
            $relative = Get-SkillPackRelativePath -Path $skillFile.FullName -Root $root
            $segments = @($relative -split '[\\/]')
            if ($segments -contains '.system') {
                continue
            }
            if ($skillFile.FullName -match '[\\/]\.codex[\\/]plugins[\\/]cache[\\/]') {
                continue
            }

            try {
                $frontmatter = Read-SkillFrontmatter -Path $skillFile.FullName
                if ([string]::IsNullOrWhiteSpace($frontmatter.Name)) {
                    throw 'frontmatter name is empty'
                }
                $installed.Add([pscustomobject]@{
                    Name      = $frontmatter.Name
                    Path      = $skillFile.DirectoryName
                    SkillFile = $skillFile.FullName
                    Root      = $root
                })
            } catch {
                $configurationErrors.Add("Invalid installed SKILL.md '$($skillFile.FullName)': $($_.Exception.Message)")
            }
        }
    } catch {
        $configurationErrors.Add("Could not scan skill root '$root': $($_.Exception.Message)")
    }
}

if ($configurationErrors.Count -gt 0) {
    $result.summary.skillsScanned = $installed.Count
    $result.configuration = @($configurationErrors | ForEach-Object { [ordered]@{ message = $_ } })
    $result.summary.configurationErrors = $configurationErrors.Count
    Complete-Doctor -Result $result -ExitCode 2
}

$result.summary.skillsScanned = $installed.Count
$installedByName = @{}
foreach ($copy in $installed) {
    if (-not $installedByName.ContainsKey($copy.Name)) {
        $installedByName[$copy.Name] = New-Object 'System.Collections.Generic.List[object]'
    }
    $installedByName[$copy.Name].Add($copy)
}

$duplicates = New-Object 'System.Collections.Generic.List[object]'
foreach ($name in @($installedByName.Keys | Sort-Object)) {
    if ($installedByName[$name].Count -gt 1) {
        $duplicates.Add([ordered]@{
            name  = $name
            paths = @($installedByName[$name] | ForEach-Object { $_.Path } | Sort-Object)
        })
    }
}
$result.duplicates = $duplicates.ToArray()
$result.summary.duplicateNames = $duplicates.Count

$manifestByName = @{}
foreach ($entry in @($manifest.skills)) {
    $manifestByName[[string]$entry.name] = $entry
}

$drift = New-Object 'System.Collections.Generic.List[object]'
foreach ($copy in $installed) {
    if (-not $manifestByName.ContainsKey($copy.Name)) {
        continue
    }

    $sourceDirectory = Join-Path $repoSkillsRoot $copy.Name
    $sourceInventory = @{}
    foreach ($file in @(Get-SkillFileInventory -Directory $sourceDirectory)) {
        $sourceInventory[$file.RelativePath] = $file.Hash
    }
    $installedInventory = @{}
    foreach ($file in @(Get-SkillFileInventory -Directory $copy.Path)) {
        $installedInventory[$file.RelativePath] = $file.Hash
    }

    $missing = @($sourceInventory.Keys | Where-Object { -not $installedInventory.ContainsKey($_) } | Sort-Object)
    $extra = @($installedInventory.Keys | Where-Object { -not $sourceInventory.ContainsKey($_) } | Sort-Object)
    $changed = @(
        $sourceInventory.Keys |
            Where-Object { $installedInventory.ContainsKey($_) -and $installedInventory[$_] -ne $sourceInventory[$_] } |
            Sort-Object
    )

    if ($missing.Count -gt 0 -or $extra.Count -gt 0 -or $changed.Count -gt 0) {
        $drift.Add([ordered]@{
            name    = $copy.Name
            path    = $copy.Path
            missing = @($missing)
            extra   = @($extra)
            changed = @($changed)
        })
    }
}
$result.drift = $drift.ToArray()
$result.summary.driftedCopies = $drift.Count

$dependencyIssues = New-Object 'System.Collections.Generic.List[object]'
foreach ($copy in $installed) {
    if (-not $manifestByName.ContainsKey($copy.Name)) {
        continue
    }
    $missingDependencies = @(
        @($manifestByName[$copy.Name].requires) |
            ForEach-Object { [string]$_ } |
            Where-Object { -not $installedByName.ContainsKey($_) } |
            Sort-Object -Unique
    )
    if ($missingDependencies.Count -gt 0) {
        $dependencyIssues.Add([ordered]@{
            name    = $copy.Name
            path    = $copy.Path
            missing = @($missingDependencies)
        })
    }
}
$result.dependencies = $dependencyIssues.ToArray()
$result.summary.dependencyIssues = $dependencyIssues.Count

$referenceIssues = New-Object 'System.Collections.Generic.List[object]'
foreach ($copy in $installed) {
    # Duplicate discovery is global, but pack-specific integrity checks only apply
    # to skills whose dependency and reference contracts exist in this manifest.
    if (-not $manifestByName.ContainsKey($copy.Name)) {
        continue
    }
    $declaredDependencies = @($manifestByName[$copy.Name].requires | ForEach-Object { [string]$_ })

    foreach ($reference in @(Get-SkillMarkdownReferences -SkillDirectory $copy.Path -SkillsRoot $copy.Root)) {
        $type = $null
        if (-not $reference.IsInsideSkills) {
            $type = 'outside-root'
        } elseif (-not $reference.Exists) {
            $type = 'missing'
        } elseif ($reference.IsCrossSkill -and $reference.TargetSkill -notin $declaredDependencies) {
            $type = 'undeclared-dependency'
        }

        if ($null -ne $type) {
            $referenceIssues.Add([ordered]@{
                name      = $copy.Name
                path      = $copy.Path
                source    = Get-SkillPackRelativePath -Path $reference.SourceFile -Root $copy.Path
                reference = $reference.Reference
                type      = $type
            })
        }
    }
}
$result.references = $referenceIssues.ToArray()
$result.summary.referenceIssues = $referenceIssues.Count

$hasProblems = (
    $duplicates.Count -gt 0 -or
    $drift.Count -gt 0 -or
    $dependencyIssues.Count -gt 0 -or
    $referenceIssues.Count -gt 0
)
$result.summary.healthy = -not $hasProblems

Complete-Doctor -Result $result -ExitCode $(if ($hasProblems) { 1 } else { 0 })
