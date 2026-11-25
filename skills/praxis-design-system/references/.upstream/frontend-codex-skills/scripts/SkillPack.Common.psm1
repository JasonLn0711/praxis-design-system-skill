Set-StrictMode -Version 2.0

function Get-SkillPackFullPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$BasePath = (Get-Location).Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-SkillPackChildPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Root,

        [switch]$AllowRoot
    )

    $candidate = (Get-SkillPackFullPath -Path $Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $rootPath = (Get-SkillPackFullPath -Path $Root).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )

    if ($AllowRoot -and $candidate.Equals($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $rootPrefix = $rootPath + [System.IO.Path]::DirectorySeparatorChar
    return $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-SkillPackRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $fullPath = Get-SkillPackFullPath -Path $Path
    $fullRoot = (Get-SkillPackFullPath -Path $Root).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar

    $rootUri = New-Object System.Uri($fullRoot)
    $pathUri = New-Object System.Uri($fullPath)
    $relativeUri = $rootUri.MakeRelativeUri($pathUri)
    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

function Read-SkillPackManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $manifestPath = Join-Path (Get-SkillPackFullPath -Path $RepoRoot) 'skills.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Manifest not found: $manifestPath"
    }

    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        throw "Manifest is not valid JSON: $($_.Exception.Message)"
    }

    if ($null -eq $manifest) {
        throw 'Manifest is empty.'
    }

    return $manifest
}

function Get-SkillPackManifestErrors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,

        [string]$SkillsRoot
    )

    $errors = New-Object 'System.Collections.Generic.List[string]'
    $manifestProperties = @($Manifest.PSObject.Properties.Name)

    if ($manifestProperties -notcontains 'name' -or [string]::IsNullOrWhiteSpace([string]$Manifest.name)) {
        $errors.Add('manifest: missing non-empty name')
    }

    if ($manifestProperties -notcontains 'version' -or [string]$Manifest.version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$') {
        $errors.Add('manifest: version must be valid SemVer')
    }

    if ($manifestProperties -notcontains 'skills' -or $null -eq $Manifest.skills) {
        $errors.Add('manifest: missing skills array')
        return @($errors)
    }

    if ($Manifest.skills -isnot [System.Array]) {
        $errors.Add('manifest: skills must be an array')
    }

    $entries = @($Manifest.skills)
    if ($entries.Count -eq 0) {
        $errors.Add('manifest: skills array must not be empty')
        return @($errors)
    }

    $nameCounts = @{}
    $entryByName = @{}

    foreach ($entry in $entries) {
        if ($null -eq $entry) {
            $errors.Add('manifest: skills contains a null entry')
            continue
        }

        $properties = @($entry.PSObject.Properties.Name)
        $name = if ($properties -contains 'name') { [string]$entry.name } else { '' }
        if ($properties -notcontains 'name' -or [string]::IsNullOrWhiteSpace($name)) {
            $errors.Add('manifest: skill entry is missing a non-empty name')
            continue
        }

        if ($entry.name -isnot [string]) {
            $errors.Add("manifest: skill name '$name' must be a string")
        }

        if ($name -notmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$') {
            $errors.Add("manifest: skill '$name' is not lower-kebab-case")
        }

        if (-not $nameCounts.ContainsKey($name)) {
            $nameCounts[$name] = 0
        }
        $nameCounts[$name]++
        if (-not $entryByName.ContainsKey($name)) {
            $entryByName[$name] = $entry
        }

        foreach ($field in @('stage', 'output')) {
            if ($properties -notcontains $field -or [string]::IsNullOrWhiteSpace([string]$entry.$field)) {
                $errors.Add("manifest: skill '$name' is missing non-empty $field")
            } elseif ($entry.$field -isnot [string]) {
                $errors.Add("manifest: skill '$name' $field must be a string")
            }
        }

        if ($properties -notcontains 'requires') {
            $errors.Add("manifest: skill '$name' is missing requires array")
        } elseif ($null -eq $entry.requires -or $entry.requires -isnot [System.Array]) {
            $errors.Add("manifest: skill '$name' requires must be an array")
        } else {
            $seenDependencies = @{}
            foreach ($dependencyValue in @($entry.requires)) {
                $dependency = [string]$dependencyValue
                if ($dependencyValue -isnot [string]) {
                    $errors.Add("manifest: dependency '$dependency' for '$name' must be a string")
                }
                if ([string]::IsNullOrWhiteSpace($dependency)) {
                    $errors.Add("manifest: skill '$name' contains an empty dependency")
                    continue
                }
                if ($dependency -notmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$') {
                    $errors.Add("manifest: dependency '$dependency' for '$name' is not lower-kebab-case")
                }
                if ($seenDependencies.ContainsKey($dependency)) {
                    $errors.Add("manifest: skill '$name' lists dependency '$dependency' more than once")
                } else {
                    $seenDependencies[$dependency] = $true
                }
                if ($dependency -eq $name) {
                    $errors.Add("manifest: skill '$name' cannot depend on itself")
                }
            }
        }

        if ($properties -contains 'optionalIntegrations') {
            if ($null -eq $entry.optionalIntegrations -or $entry.optionalIntegrations -isnot [System.Array]) {
                $errors.Add("manifest: skill '$name' optionalIntegrations must be an array when present")
            } else {
                $seenOptional = @{}
                foreach ($integrationValue in @($entry.optionalIntegrations)) {
                    $integration = [string]$integrationValue
                    if ($integrationValue -isnot [string]) {
                        $errors.Add("manifest: optional integration '$integration' for '$name' must be a string")
                    }
                    if ([string]::IsNullOrWhiteSpace($integration)) {
                        $errors.Add("manifest: skill '$name' contains an empty optional integration")
                        continue
                    }
                    if ($integration -notmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$') {
                        $errors.Add("manifest: optional integration '$integration' for '$name' is not lower-kebab-case")
                    }
                    if ($seenOptional.ContainsKey($integration)) {
                        $errors.Add("manifest: skill '$name' lists optional integration '$integration' more than once")
                    } else {
                        $seenOptional[$integration] = $true
                    }
                    if ($integration -eq $name) {
                        $errors.Add("manifest: skill '$name' cannot list itself as an optional integration")
                    }
                }
            }
        }
    }

    foreach ($name in @($nameCounts.Keys | Sort-Object)) {
        if ($nameCounts[$name] -gt 1) {
            $errors.Add("manifest: duplicate skill name '$name'")
        }
    }

    $knownNames = @{}
    foreach ($name in $entryByName.Keys) {
        $knownNames[$name] = $true
    }

    foreach ($name in @($entryByName.Keys | Sort-Object)) {
        $entry = $entryByName[$name]
        if (@($entry.PSObject.Properties.Name) -notcontains 'requires' -or $entry.requires -isnot [System.Array]) {
            continue
        }
        foreach ($dependencyValue in @($entry.requires)) {
            $dependency = [string]$dependencyValue
            if (-not [string]::IsNullOrWhiteSpace($dependency) -and -not $knownNames.ContainsKey($dependency)) {
                $errors.Add("manifest: skill '$name' requires unknown skill '$dependency'")
            }
        }
    }

    if ($knownNames.Count -gt 0) {
        $indegree = @{}
        $dependents = @{}
        foreach ($name in $knownNames.Keys) {
            $indegree[$name] = 0
            $dependents[$name] = New-Object 'System.Collections.Generic.List[string]'
        }

        foreach ($name in $knownNames.Keys) {
            $entry = $entryByName[$name]
            if (@($entry.PSObject.Properties.Name) -notcontains 'requires' -or $entry.requires -isnot [System.Array]) {
                continue
            }
            foreach ($dependencyValue in @($entry.requires)) {
                $dependency = [string]$dependencyValue
                if ($dependency -ne $name -and $knownNames.ContainsKey($dependency)) {
                    $indegree[$name]++
                    $dependents[$dependency].Add($name)
                }
            }
        }

        $queue = New-Object 'System.Collections.Generic.Queue[string]'
        foreach ($name in @($knownNames.Keys | Sort-Object)) {
            if ($indegree[$name] -eq 0) {
                $queue.Enqueue($name)
            }
        }

        $processed = 0
        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            $processed++
            foreach ($dependent in $dependents[$current]) {
                $indegree[$dependent]--
                if ($indegree[$dependent] -eq 0) {
                    $queue.Enqueue($dependent)
                }
            }
        }

        if ($processed -lt $knownNames.Count) {
            $cycleNames = @($indegree.Keys | Where-Object { $indegree[$_] -gt 0 } | Sort-Object)
            $errors.Add("manifest: dependency cycle detected involving $($cycleNames -join ', ')")
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($SkillsRoot)) {
        $fullSkillsRoot = Get-SkillPackFullPath -Path $SkillsRoot
        if (-not (Test-Path -LiteralPath $fullSkillsRoot -PathType Container)) {
            $errors.Add("manifest: skills directory not found: $fullSkillsRoot")
        } else {
            $directoryNames = @(Get-ChildItem -LiteralPath $fullSkillsRoot -Directory | Select-Object -ExpandProperty Name)
            foreach ($name in @($knownNames.Keys | Sort-Object)) {
                if ($name -notin $directoryNames) {
                    $errors.Add("manifest: skill '$name' has no matching directory")
                }
            }
            foreach ($directoryName in @($directoryNames | Sort-Object)) {
                if (-not $knownNames.ContainsKey($directoryName)) {
                    $errors.Add("manifest: directory '$directoryName' is not declared in skills.json")
                }
            }
        }
    }

    return @($errors)
}

function Get-SkillPackDependencyOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,

        [Parameter(Mandatory = $true)]
        [string[]]$Requested
    )

    $manifestErrors = @(Get-SkillPackManifestErrors -Manifest $Manifest)
    if ($manifestErrors.Count -gt 0) {
        throw ($manifestErrors -join [Environment]::NewLine)
    }

    $entryByName = @{}
    foreach ($entry in @($Manifest.skills)) {
        $entryByName[[string]$entry.name] = $entry
    }

    $requestedNames = New-Object 'System.Collections.Generic.List[string]'
    $requestedSet = @{}
    foreach ($nameValue in @($Requested)) {
        $name = [string]$nameValue
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }
        if (-not $entryByName.ContainsKey($name)) {
            throw "Unknown skill '$name'. Available: $(@($entryByName.Keys | Sort-Object) -join ', ')"
        }
        if (-not $requestedSet.ContainsKey($name)) {
            $requestedSet[$name] = $true
            $requestedNames.Add($name)
        }
    }

    $order = New-Object 'System.Collections.Generic.List[string]'
    $visited = @{}
    $visiting = @{}
    $visit = $null
    $visit = {
        param([string]$Name)

        if ($visiting.ContainsKey($Name)) {
            throw "Dependency cycle detected while resolving '$Name'."
        }
        if ($visited.ContainsKey($Name)) {
            return
        }

        $visiting[$Name] = $true
        foreach ($dependencyValue in @($entryByName[$Name].requires)) {
            & $visit ([string]$dependencyValue)
        }
        $visiting.Remove($Name)
        $visited[$Name] = $true
        $order.Add($Name)
    }

    foreach ($name in $requestedNames) {
        & $visit $name
    }

    $addedDependencies = @($order | Where-Object { -not $requestedSet.ContainsKey($_) })
    return [pscustomobject]@{
        Requested         = @($requestedNames)
        AddedDependencies = @($addedDependencies)
        InstallOrder      = @($order)
    }
}

function ConvertFrom-SkillPackYamlScalar {
    param([string]$Value)

    $trimmed = $Value.Trim()
    $startsDouble = $trimmed.StartsWith('"')
    $endsDouble = $trimmed.EndsWith('"')
    $startsSingle = $trimmed.StartsWith("'")
    $endsSingle = $trimmed.EndsWith("'")
    if ($startsDouble -xor $endsDouble) {
        throw 'unterminated double-quoted YAML scalar'
    }
    if ($startsSingle -xor $endsSingle) {
        throw 'unterminated single-quoted YAML scalar'
    }
    if ($trimmed.Length -ge 2 -and $trimmed[0] -eq '"' -and $trimmed[$trimmed.Length - 1] -eq '"') {
        $inner = $trimmed.Substring(1, $trimmed.Length - 2)
        return $inner.Replace('\"', '"').Replace('\\', '\')
    }
    if ($trimmed.Length -ge 2 -and $trimmed[0] -eq "'" -and $trimmed[$trimmed.Length - 1] -eq "'") {
        return $trimmed.Substring(1, $trimmed.Length - 2).Replace("''", "'")
    }
    if ($trimmed -match ':\s') {
        throw "plain YAML scalar contains ': '; quote the value or use a block scalar"
    }
    return $trimmed
}

function Read-SkillFrontmatter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = Get-SkillPackFullPath -Path $Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "SKILL.md not found: $fullPath"
    }

    $lines = @(Get-Content -LiteralPath $fullPath -Encoding UTF8)
    if ($lines.Count -lt 3 -or $lines[0] -ne '---') {
        throw 'frontmatter must start with --- on the first line'
    }

    $closingIndex = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') {
            $closingIndex = $i
            break
        }
    }
    if ($closingIndex -lt 0) {
        throw 'frontmatter is missing its closing --- delimiter'
    }

    $values = @{}
    $keys = New-Object 'System.Collections.Generic.List[string]'
    $i = 1
    $allowsNestedBlock = $false
    while ($i -lt $closingIndex) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) {
            $i++
            continue
        }

        if ($line -match '^\s') {
            if ($allowsNestedBlock) {
                $i++
                continue
            }
            throw "invalid frontmatter indentation on line $($i + 1): $line"
        }

        $match = [regex]::Match($line, '^(?<key>[A-Za-z0-9_-]+):(?:\s*(?<value>.*))$')
        if (-not $match.Success) {
            throw "invalid frontmatter line $($i + 1): $line"
        }

        $key = $match.Groups['key'].Value
        $rawValue = $match.Groups['value'].Value
        $keys.Add($key)
        if ($values.ContainsKey($key)) {
            throw "duplicate frontmatter key '$key'"
        }

        if ($rawValue -match '^(?<style>[|>])(?<chomp>[-+]?)$') {
            $allowsNestedBlock = $false
            $style = $Matches['style']
            $blockLines = New-Object 'System.Collections.Generic.List[string]'
            $i++
            while ($i -lt $closingIndex) {
                $candidate = $lines[$i]
                if (-not [string]::IsNullOrWhiteSpace($candidate) -and $candidate -notmatch '^\s') {
                    break
                }
                $blockLines.Add($candidate)
                $i++
            }

            $indents = @(
                $blockLines |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                    ForEach-Object { ([regex]::Match($_, '^\s*')).Value.Length }
            )
            $indent = if ($indents.Count -gt 0) { ($indents | Measure-Object -Minimum).Minimum } else { 0 }
            $normalized = @(
                $blockLines | ForEach-Object {
                    if ([string]::IsNullOrWhiteSpace($_)) {
                        ''
                    } elseif ($_.Length -ge $indent) {
                        $_.Substring($indent)
                    } else {
                        $_.TrimStart()
                    }
                }
            )

            if ($style -eq '|') {
                $values[$key] = ($normalized -join "`n").TrimEnd("`r", "`n")
            } else {
                $paragraphs = New-Object 'System.Collections.Generic.List[string]'
                $paragraph = New-Object 'System.Collections.Generic.List[string]'
                foreach ($blockLine in $normalized) {
                    if ([string]::IsNullOrWhiteSpace($blockLine)) {
                        if ($paragraph.Count -gt 0) {
                            $paragraphs.Add(($paragraph -join ' '))
                            $paragraph.Clear()
                        }
                    } else {
                        $paragraph.Add($blockLine.Trim())
                    }
                }
                if ($paragraph.Count -gt 0) {
                    $paragraphs.Add(($paragraph -join ' '))
                }
                $values[$key] = ($paragraphs -join "`n`n")
            }
            continue
        }

        if ($key -in @('name', 'description') -and $rawValue.Trim() -match '^(?:true|false|null|~|[-+]?\d+(?:\.\d+)?)$') {
            throw "frontmatter '$key' must be a string, not an unquoted YAML scalar"
        }
        $values[$key] = ConvertFrom-SkillPackYamlScalar -Value $rawValue
        $allowsNestedBlock = [string]::IsNullOrWhiteSpace($rawValue)
        $i++
    }

    return [pscustomobject]@{
        Name        = if ($values.ContainsKey('name')) { [string]$values['name'] } else { $null }
        Description = if ($values.ContainsKey('description')) { [string]$values['description'] } else { $null }
        Keys        = @($keys)
        EndLine     = $closingIndex + 1
    }
}

function Get-SkillMarkdownReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillDirectory,

        [Parameter(Mandatory = $true)]
        [string]$SkillsRoot
    )

    $fullSkillDirectory = Get-SkillPackFullPath -Path $SkillDirectory
    $fullSkillsRoot = Get-SkillPackFullPath -Path $SkillsRoot
    $currentSkillName = Split-Path -Leaf $fullSkillDirectory
    $results = New-Object 'System.Collections.Generic.List[object]'
    $pattern = '(?<![A-Za-z0-9._/-])(?<path>(?:(?:\.\.?/)|(?:[A-Za-z0-9._-]+/))+(?:[A-Za-z0-9._-]+\.md))(?![A-Za-z0-9._/-])'

    foreach ($markdownFile in @(Get-ChildItem -LiteralPath $fullSkillDirectory -Filter '*.md' -File -Recurse | Sort-Object FullName)) {
        $content = Get-Content -LiteralPath $markdownFile.FullName -Raw -Encoding UTF8
        $seen = @{}
        foreach ($match in [regex]::Matches($content, $pattern)) {
            $reference = $match.Groups['path'].Value
            $key = "$($markdownFile.FullName)|$reference"
            if ($seen.ContainsKey($key)) {
                continue
            }
            $seen[$key] = $true

            $platformPath = $reference.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $resolvedPath = Get-SkillPackFullPath -Path $platformPath -BasePath $markdownFile.DirectoryName
            $insideSkills = Test-SkillPackChildPath -Path $resolvedPath -Root $fullSkillsRoot -AllowRoot
            $targetSkill = $null
            $isCrossSkill = $false
            if ($insideSkills) {
                $relativeToSkills = Get-SkillPackRelativePath -Path $resolvedPath -Root $fullSkillsRoot
                $segments = @($relativeToSkills -split '[\\/]')
                if ($segments.Count -gt 0) {
                    $targetSkill = $segments[0]
                    $isCrossSkill = $targetSkill -ne $currentSkillName
                }
            }

            $results.Add([pscustomobject]@{
                Skill          = $currentSkillName
                SourceFile     = $markdownFile.FullName
                Reference      = $reference
                ResolvedPath   = $resolvedPath
                IsInsideSkills = $insideSkills
                Exists         = Test-Path -LiteralPath $resolvedPath -PathType Leaf
                TargetSkill    = $targetSkill
                IsCrossSkill   = $isCrossSkill
            })
        }
    }

    return $results.ToArray()
}

function Get-SkillFileInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $fullDirectory = Get-SkillPackFullPath -Path $Directory
    if (-not (Test-Path -LiteralPath $fullDirectory -PathType Container)) {
        throw "Directory not found: $fullDirectory"
    }

    $inventory = New-Object 'System.Collections.Generic.List[object]'
    foreach ($file in @(Get-ChildItem -LiteralPath $fullDirectory -File -Recurse | Sort-Object FullName)) {
        $relativePath = (Get-SkillPackRelativePath -Path $file.FullName -Root $fullDirectory).Replace('\', '/')
        $inventory.Add([pscustomobject]@{
            RelativePath = $relativePath
            Hash         = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }
    return $inventory.ToArray()
}

Export-ModuleMember -Function @(
    'Get-SkillPackFullPath',
    'Test-SkillPackChildPath',
    'Get-SkillPackRelativePath',
    'Read-SkillPackManifest',
    'Get-SkillPackManifestErrors',
    'Get-SkillPackDependencyOrder',
    'Read-SkillFrontmatter',
    'Get-SkillMarkdownReferences',
    'Get-SkillFileInventory'
)
