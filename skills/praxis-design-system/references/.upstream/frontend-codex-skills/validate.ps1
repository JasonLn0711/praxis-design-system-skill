[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsRoot = Join-Path $repoRoot 'skills'
$modulePath = Join-Path $repoRoot 'scripts\SkillPack.Common.psm1'
$errors = New-Object 'System.Collections.Generic.List[string]'

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    Write-Error "Shared module not found: $modulePath"
    exit 1
}
Import-Module -Name $modulePath -Force

$manifest = $null
try {
    $manifest = Read-SkillPackManifest -RepoRoot $repoRoot
} catch {
    $errors.Add($_.Exception.Message)
}

if ($null -ne $manifest) {
    foreach ($manifestError in @(Get-SkillPackManifestErrors -Manifest $manifest -SkillsRoot $skillsRoot)) {
        $errors.Add($manifestError)
    }
}

if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) {
    $errors.Add("skills directory not found: $skillsRoot")
    Write-Error ("Validation failed:`n- " + ($errors -join "`n- "))
    exit 1
}

$skillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name)
if ($skillDirs.Count -eq 0) {
    $errors.Add('no skill directories found')
}

$manifestEntries = @{}
if ($null -ne $manifest) {
    foreach ($entry in @($manifest.skills)) {
        $properties = @($entry.PSObject.Properties.Name)
        if ($properties -contains 'name' -and -not [string]::IsNullOrWhiteSpace([string]$entry.name) -and -not $manifestEntries.ContainsKey([string]$entry.name)) {
            $manifestEntries[[string]$entry.name] = $entry
        }
    }
}

foreach ($dir in $skillDirs) {
    $skillFile = Join-Path $dir.FullName 'SKILL.md'
    $agentFile = Join-Path $dir.FullName 'agents\openai.yaml'

    if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
        $errors.Add("$($dir.Name): missing SKILL.md")
    } else {
        try {
            $frontmatter = Read-SkillFrontmatter -Path $skillFile
            foreach ($key in @($frontmatter.Keys)) {
                if ($key -notin @('name', 'description', 'metadata')) {
                    $errors.Add("$($dir.Name): unsupported package frontmatter key '$key'")
                }
            }

            if ([string]::IsNullOrWhiteSpace($frontmatter.Name)) {
                $errors.Add("$($dir.Name): missing frontmatter name")
            } elseif ($frontmatter.Name -notmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$') {
                $errors.Add("$($dir.Name): frontmatter name must be lower-kebab-case")
            } elseif ($frontmatter.Name -ne $dir.Name) {
                $errors.Add("$($dir.Name): frontmatter name '$($frontmatter.Name)' does not match folder")
            }

            if ([string]::IsNullOrWhiteSpace($frontmatter.Description)) {
                $errors.Add("$($dir.Name): frontmatter description must not be empty")
            }
        } catch {
            $errors.Add("$($dir.Name): invalid frontmatter: $($_.Exception.Message)")
        }
    }

    if (-not (Test-Path -LiteralPath $agentFile -PathType Leaf)) {
        $errors.Add("$($dir.Name): missing agents/openai.yaml")
    } else {
        $agentLines = @(Get-Content -LiteralPath $agentFile -Encoding UTF8)
        $nonEmptyLines = @($agentLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($nonEmptyLines.Count -eq 0 -or $nonEmptyLines[0] -ne 'interface:') {
            $errors.Add("$($dir.Name): agents/openai.yaml must start with interface:")
        }

        for ($lineIndex = 0; $lineIndex -lt $agentLines.Count; $lineIndex++) {
            $line = $agentLines[$lineIndex]
            if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
                continue
            }
            $scalar = [regex]::Match($line, '^\s*(?:-\s*)?[A-Za-z0-9_]+:\s*(?<value>\S.*)\s*$')
            if (-not $scalar.Success) {
                continue
            }
            $value = $scalar.Groups['value'].Value.Trim()
            $isQuoted = (
                ($value.Length -ge 2 -and $value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.Length -ge 2 -and $value.StartsWith("'") -and $value.EndsWith("'"))
            )
            $isNonStringScalar = $value -match '^(?:true|false|null|~|[-+]?\d+(?:\.\d+)?|\[\]|\{\})$'
            if (-not $isQuoted -and -not $isNonStringScalar) {
                $errors.Add("$($dir.Name): agents/openai.yaml line $($lineIndex + 1) contains an unquoted string value")
            }
        }

        $interfaceLines = @()
        $interfaceIndex = [Array]::IndexOf($agentLines, 'interface:')
        if ($interfaceIndex -ge 0) {
            $interfaceBuffer = New-Object 'System.Collections.Generic.List[string]'
            for ($lineIndex = $interfaceIndex + 1; $lineIndex -lt $agentLines.Count; $lineIndex++) {
                $line = $agentLines[$lineIndex]
                if (-not [string]::IsNullOrWhiteSpace($line) -and $line -match '^\S') {
                    break
                }
                $interfaceBuffer.Add($line)
            }
            $interfaceLines = $interfaceBuffer.ToArray()
        }

        $agentValues = @{}
        foreach ($field in @('display_name', 'short_description', 'default_prompt')) {
            $fieldLines = @($interfaceLines | Where-Object { $_ -match "^  $([regex]::Escape($field)):\s*" })
            if ($fieldLines.Count -eq 0) {
                $errors.Add("$($dir.Name): agents/openai.yaml is missing interface.$field")
                continue
            }
            if ($fieldLines.Count -gt 1) {
                $errors.Add("$($dir.Name): agents/openai.yaml repeats interface.$field")
                continue
            }

            $quotedPattern = '^  {0}:\s*"(?<value>(?:[^"\\]|\\.)*)"\s*$' -f [regex]::Escape($field)
            $quoted = [regex]::Match($fieldLines[0], $quotedPattern)
            $singleQuotedPattern = "^  {0}:\s*'(?<value>(?:[^']|'')*)'\s*$" -f [regex]::Escape($field)
            $singleQuoted = [regex]::Match($fieldLines[0], $singleQuotedPattern)
            if ($quoted.Success) {
                $agentValues[$field] = $quoted.Groups['value'].Value.Replace('\"', '"').Replace('\\', '\')
            } elseif ($singleQuoted.Success) {
                $agentValues[$field] = $singleQuoted.Groups['value'].Value.Replace("''", "'")
            } else {
                $errors.Add("$($dir.Name): agents/openai.yaml interface.$field must be a quoted string")
                continue
            }
        }

        if ($agentValues.ContainsKey('display_name') -and [string]::IsNullOrWhiteSpace([string]$agentValues['display_name'])) {
            $errors.Add("$($dir.Name): agents/openai.yaml display_name must not be empty")
        }
        if ($agentValues.ContainsKey('short_description')) {
            $length = ([string]$agentValues['short_description']).Length
            if ($length -lt 25 -or $length -gt 64) {
                $errors.Add("$($dir.Name): agents/openai.yaml short_description must be 25-64 characters (found $length)")
            }
        }
        if ($agentValues.ContainsKey('default_prompt')) {
            $prompt = [string]$agentValues['default_prompt']
            if ($prompt.Length -gt 180) {
                $errors.Add("$($dir.Name): agents/openai.yaml default_prompt exceeds 180 characters (found $($prompt.Length))")
            }
            $requiredInvocation = '$' + $dir.Name
            if (-not $prompt.Contains($requiredInvocation)) {
                $errors.Add("$($dir.Name): agents/openai.yaml default_prompt must contain $requiredInvocation")
            }
        }

        $policyIndex = [Array]::IndexOf($agentLines, 'policy:')
        if ($policyIndex -ge 0) {
            $policyMatches = @(
                $agentLines |
                    Where-Object { $_ -match '^  allow_implicit_invocation:\s*' }
            )
            if ($policyMatches.Count -gt 1) {
                $errors.Add("$($dir.Name): agents/openai.yaml repeats policy.allow_implicit_invocation")
            } elseif ($policyMatches.Count -eq 1 -and $policyMatches[0] -notmatch '^  allow_implicit_invocation:\s*(?:true|false)\s*$') {
                $errors.Add("$($dir.Name): agents/openai.yaml policy.allow_implicit_invocation must be a YAML boolean")
            }
        }
    }

    foreach ($file in @(Get-ChildItem -LiteralPath $dir.FullName -File -Recurse)) {
        try {
            $fileContent = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
            if ($fileContent -match '\[TODO\]|TODO:\s+Replace|<PLACEHOLDER>|PLACEHOLDER_TEXT') {
                $relativeFile = Get-SkillPackRelativePath -Path $file.FullName -Root $dir.FullName
                $errors.Add("$($dir.Name): template placeholder found in $relativeFile")
            }
        } catch {
            $relativeFile = Get-SkillPackRelativePath -Path $file.FullName -Root $dir.FullName
            $errors.Add("$($dir.Name): could not scan $relativeFile for placeholders: $($_.Exception.Message)")
        }
    }

    $declaredDependencies = @()
    if ($manifestEntries.ContainsKey($dir.Name)) {
        $entry = $manifestEntries[$dir.Name]
        if (@($entry.PSObject.Properties.Name) -contains 'requires' -and $entry.requires -is [System.Array]) {
            $declaredDependencies = @($entry.requires | ForEach-Object { [string]$_ })
        }
    }

    try {
        $references = @(Get-SkillMarkdownReferences -SkillDirectory $dir.FullName -SkillsRoot $skillsRoot)
    } catch {
        $errors.Add("$($dir.Name): could not scan Markdown references: $($_.Exception.Message)")
        $references = @()
    }

    foreach ($reference in $references) {
        $relativeSource = Get-SkillPackRelativePath -Path $reference.SourceFile -Root $dir.FullName
        if (-not $reference.IsInsideSkills) {
            $errors.Add("$($dir.Name): reference '$($reference.Reference)' in $relativeSource escapes skills/")
            continue
        }
        if (-not $reference.Exists) {
            $errors.Add("$($dir.Name): missing referenced file '$($reference.Reference)' in $relativeSource")
        }
        if ($reference.IsCrossSkill -and $reference.TargetSkill -notin $declaredDependencies) {
            $errors.Add("$($dir.Name): cross-skill reference '$($reference.Reference)' in $relativeSource requires '$($reference.TargetSkill)' in skills.json")
        }
    }

    Write-Host "Checked $($dir.Name)"
}

if ($errors.Count -gt 0) {
    Write-Error ("Validation failed with $($errors.Count) error(s):`n- " + ($errors -join "`n- "))
    exit 1
}

Write-Host "Validation passed for $($skillDirs.Count) skills (pack $($manifest.version))."
