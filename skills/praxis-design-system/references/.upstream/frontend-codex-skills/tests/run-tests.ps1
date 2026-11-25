[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$powershellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("frontend-codex-skills-tests-" + [guid]::NewGuid().ToString('N'))
$failures = New-Object 'System.Collections.Generic.List[string]'
$passed = 0
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Equal {
    param(
        $Expected,
        $Actual,
        [string]$Message
    )
    if ([string]$Expected -ne [string]$Actual) {
        throw "$Message Expected '$Expected', found '$Actual'."
    }
}

function Invoke-PackScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [string[]]$Arguments = @()
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output.Trim()
    }
}

function Copy-TestRepository {
    $destination = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    foreach ($item in @('install.ps1', 'validate.ps1', 'doctor.ps1', 'skills.json', 'skills', 'scripts')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $item) -Destination (Join-Path $destination $item) -Recurse
    }
    return $destination
}

function Read-TestManifest {
    param([string]$TestRepo)
    return Get-Content -LiteralPath (Join-Path $TestRepo 'skills.json') -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Save-TestManifest {
    param(
        [string]$TestRepo,
        [object]$Manifest
    )
    $json = $Manifest | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText((Join-Path $TestRepo 'skills.json'), $json + [Environment]::NewLine, $utf8NoBom)
}

function Invoke-ValidationFailure {
    param([string]$TestRepo)
    $result = Invoke-PackScript -ScriptPath (Join-Path $TestRepo 'validate.ps1')
    Assert-True ($result.ExitCode -ne 0) "Expected validation to fail. Output: $($result.Output)"
    return $result
}

function Install-AllToTemp {
    param([string]$TestRepo)
    $destination = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
    $result = Invoke-PackScript -ScriptPath (Join-Path $TestRepo 'install.ps1') -Arguments @('-Destination', $destination)
    Assert-Equal 0 $result.ExitCode "Full temp installation failed. $($result.Output)"
    return $destination
}

function ConvertFrom-DoctorJson {
    param([object]$Result)
    try {
        return $Result.Output | ConvertFrom-Json
    } catch {
        throw "Doctor did not return valid JSON. Output: $($Result.Output)"
    }
}

function Invoke-TestCase {
    param(
        [string]$Name,
        [scriptblock]$Body
    )

    try {
        & $Body
        $script:passed++
        Write-Host "PASS $Name" -ForegroundColor Green
    } catch {
        $script:failures.Add("$Name`: $($_.Exception.Message)")
        Write-Host "FAIL $Name`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    Invoke-TestCase '1. Current repository validates' {
        $result = Invoke-PackScript -ScriptPath (Join-Path $repoRoot 'validate.ps1')
        Assert-Equal 0 $result.ExitCode "Repository validation failed. $($result.Output)"
    }

    Invoke-TestCase '2. Multiline frontmatter description validates' {
        foreach ($style in @('|', '>', '|-', '>-')) {
            $testRepo = Copy-TestRepository
            $skillPath = Join-Path $testRepo 'skills\frontend-acceptance-review\SKILL.md'
            $content = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
            $replacement = @"
---
name: frontend-acceptance-review
description: $style
  Use when a finished frontend needs acceptance review.
  This multiline description remains implementation-ready.
---
"@.TrimEnd("`r", "`n")
            $updated = [regex]::Replace($content, '\A---\r?\n.*?\r?\n---', $replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            [System.IO.File]::WriteAllText($skillPath, $updated, $utf8NoBom)
            $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'validate.ps1')
            Assert-Equal 0 $result.ExitCode "Multiline description style '$style' was rejected. $($result.Output)"
        }

        $quotedRepo = Copy-TestRepository
        $quotedSkillPath = Join-Path $quotedRepo 'skills\frontend-acceptance-review\SKILL.md'
        $quotedContent = Get-Content -LiteralPath $quotedSkillPath -Raw -Encoding UTF8
        $quotedReplacement = @"
---
name: 'frontend-acceptance-review'
description: "Use when a finished frontend needs a quoted acceptance description."
---
"@.TrimEnd("`r", "`n")
        $quotedUpdated = [regex]::Replace($quotedContent, '\A---\r?\n.*?\r?\n---', $quotedReplacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        [System.IO.File]::WriteAllText($quotedSkillPath, $quotedUpdated, $utf8NoBom)
        $quotedResult = Invoke-PackScript -ScriptPath (Join-Path $quotedRepo 'validate.ps1')
        Assert-Equal 0 $quotedResult.ExitCode "Quoted frontmatter was rejected. $($quotedResult.Output)"

        foreach ($invalidFrontmatter in @(
            "---`nname: frontend-acceptance-review`ndescription: Use when architecture: component boundaries`n---",
            "---`nname: 'frontend-acceptance-review`ndescription: Use when reviewing a finished frontend.`n---",
            "---`nname: frontend-acceptance-review`n description: invalid indentation`n---",
            "---`nname: frontend-acceptance-review`nname: frontend-acceptance-review`ndescription: Duplicate key.`n---",
            "---`nname: frontend-acceptance-review`ndescription: false`n---"
        )) {
            $invalidRepo = Copy-TestRepository
            $invalidPath = Join-Path $invalidRepo 'skills\frontend-acceptance-review\SKILL.md'
            $invalidContent = Get-Content -LiteralPath $invalidPath -Raw -Encoding UTF8
            $invalidUpdated = [regex]::Replace($invalidContent, '\A---\r?\n.*?\r?\n---', $invalidFrontmatter, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            [System.IO.File]::WriteAllText($invalidPath, $invalidUpdated, $utf8NoBom)
            Invoke-ValidationFailure -TestRepo $invalidRepo | Out-Null
        }

        $colonBlockRepo = Copy-TestRepository
        $colonBlockPath = Join-Path $colonBlockRepo 'skills\frontend-acceptance-review\SKILL.md'
        $colonBlockContent = Get-Content -LiteralPath $colonBlockPath -Raw -Encoding UTF8
        $colonBlockFrontmatter = "---`nname: frontend-acceptance-review`ndescription: >-`n  Use when architecture: component boundaries need review.`n---"
        $colonBlockUpdated = [regex]::Replace($colonBlockContent, '\A---\r?\n.*?\r?\n---', $colonBlockFrontmatter, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        [System.IO.File]::WriteAllText($colonBlockPath, $colonBlockUpdated, $utf8NoBom)
        $colonBlockResult = Invoke-PackScript -ScriptPath (Join-Path $colonBlockRepo 'validate.ps1')
        Assert-Equal 0 $colonBlockResult.ExitCode "Block scalar with colon was rejected. $($colonBlockResult.Output)"
    }

    Invoke-TestCase '3. Invalid manifest graph cases fail' {
        $unknownRepo = Copy-TestRepository
        $manifest = Read-TestManifest -TestRepo $unknownRepo
        $manifest.skills = @($manifest.skills) + @([pscustomobject]@{
            name = 'unknown-manifest-skill'; stage = 'test'; output = 'Test'; requires = @()
        })
        Save-TestManifest -TestRepo $unknownRepo -Manifest $manifest
        Invoke-ValidationFailure -TestRepo $unknownRepo | Out-Null

        $duplicateRepo = Copy-TestRepository
        $manifest = Read-TestManifest -TestRepo $duplicateRepo
        $manifest.skills = @($manifest.skills) + @($manifest.skills[0])
        Save-TestManifest -TestRepo $duplicateRepo -Manifest $manifest
        Invoke-ValidationFailure -TestRepo $duplicateRepo | Out-Null

        $selfRepo = Copy-TestRepository
        $manifest = Read-TestManifest -TestRepo $selfRepo
        $manifest.skills[0].requires = [object[]]@([string]$manifest.skills[0].name)
        Save-TestManifest -TestRepo $selfRepo -Manifest $manifest
        Invoke-ValidationFailure -TestRepo $selfRepo | Out-Null

        $cycleRepo = Copy-TestRepository
        $manifest = Read-TestManifest -TestRepo $cycleRepo
        ($manifest.skills | Where-Object name -eq 'web-ui-designer').requires = [object[]]@('frontend-design-planner')
        Save-TestManifest -TestRepo $cycleRepo -Manifest $manifest
        Invoke-ValidationFailure -TestRepo $cycleRepo | Out-Null

        $optionalTypeRepo = Copy-TestRepository
        $manifest = Read-TestManifest -TestRepo $optionalTypeRepo
        ($manifest.skills | Where-Object name -eq 'web-ui-designer').optionalIntegrations = 'design-taste-frontend'
        Save-TestManifest -TestRepo $optionalTypeRepo -Manifest $manifest
        Invoke-ValidationFailure -TestRepo $optionalTypeRepo | Out-Null

        $optionalDuplicateRepo = Copy-TestRepository
        $manifest = Read-TestManifest -TestRepo $optionalDuplicateRepo
        ($manifest.skills | Where-Object name -eq 'web-ui-designer').optionalIntegrations = [object[]]@('design-taste-frontend', 'design-taste-frontend')
        Save-TestManifest -TestRepo $optionalDuplicateRepo -Manifest $manifest
        Invoke-ValidationFailure -TestRepo $optionalDuplicateRepo | Out-Null
    }

    Invoke-TestCase '4. Missing invocation and oversized prompt fail' {
        $missingRepo = Copy-TestRepository
        $agentPath = Join-Path $missingRepo 'skills\web-ui-designer\agents\openai.yaml'
        $content = Get-Content -LiteralPath $agentPath -Raw -Encoding UTF8
        $content = [regex]::Replace($content, '(?m)^  default_prompt:.*$', '  default_prompt: "Create an implementation-ready Web UI design brief."')
        [System.IO.File]::WriteAllText($agentPath, $content, $utf8NoBom)
        Invoke-ValidationFailure -TestRepo $missingRepo | Out-Null

        $longRepo = Copy-TestRepository
        $agentPath = Join-Path $longRepo 'skills\web-ui-designer\agents\openai.yaml'
        $longPrompt = 'Use $web-ui-designer to ' + ('create a detailed implementation-ready interface direction with explicit product context and durable design constraints. ' * 3)
        $content = Get-Content -LiteralPath $agentPath -Raw -Encoding UTF8
        $content = [regex]::Replace($content, '(?m)^  default_prompt:.*$', ('  default_prompt: "' + $longPrompt.Trim() + '"'))
        [System.IO.File]::WriteAllText($agentPath, $content, $utf8NoBom)
        Invoke-ValidationFailure -TestRepo $longRepo | Out-Null

        $booleanRepo = Copy-TestRepository
        $booleanAgentPath = Join-Path $booleanRepo 'skills\web-ui-designer\agents\openai.yaml'
        [System.IO.File]::AppendAllText($booleanAgentPath, "`npolicy:`n  allow_implicit_invocation: false`n", $utf8NoBom)
        $booleanResult = Invoke-PackScript -ScriptPath (Join-Path $booleanRepo 'validate.ps1')
        Assert-Equal 0 $booleanResult.ExitCode "Valid YAML boolean was rejected. $($booleanResult.Output)"

        $stringBooleanRepo = Copy-TestRepository
        $stringBooleanAgentPath = Join-Path $stringBooleanRepo 'skills\web-ui-designer\agents\openai.yaml'
        [System.IO.File]::AppendAllText($stringBooleanAgentPath, "`npolicy:`n  allow_implicit_invocation: `"false`"`n", $utf8NoBom)
        Invoke-ValidationFailure -TestRepo $stringBooleanRepo | Out-Null
    }

    Invoke-TestCase '5. Broken and undeclared Markdown references fail' {
        $brokenRepo = Copy-TestRepository
        $skillPath = Join-Path $brokenRepo 'skills\web-ui-designer\SKILL.md'
        [System.IO.File]::AppendAllText($skillPath, "`r`nLoad ``references/not-present.md`` for this test.`r`n", $utf8NoBom)
        Invoke-ValidationFailure -TestRepo $brokenRepo | Out-Null

        $undeclaredRepo = Copy-TestRepository
        $manifest = Read-TestManifest -TestRepo $undeclaredRepo
        ($manifest.skills | Where-Object name -eq 'frontend-design-planner').requires = [object[]]@()
        Save-TestManifest -TestRepo $undeclaredRepo -Manifest $manifest
        Invoke-ValidationFailure -TestRepo $undeclaredRepo | Out-Null
    }

    Invoke-TestCase '6. Selected install includes the exact dependency closure' {
        $testRepo = Copy-TestRepository
        $destination = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'install.ps1') -Arguments @(
            '-Skills', 'frontend-implementation', '-Destination', $destination
        )
        Assert-Equal 0 $result.ExitCode "Selected install failed. $($result.Output)"
        $actual = @(Get-ChildItem -LiteralPath $destination -Directory | Select-Object -ExpandProperty Name | Sort-Object)
        $expected = @('frontend-code-architecture', 'frontend-implementation', 'web-ui-designer')
        Assert-Equal ($expected -join ',') ($actual -join ',') 'Dependency closure did not match.'
        Assert-True ($result.Output -match 'Requested: frontend-implementation') 'Installer did not report Requested.'
        Assert-True ($result.Output -match 'Added dependencies: web-ui-designer, frontend-code-architecture') 'Installer did not report added dependencies in dependency order.'
    }

    Invoke-TestCase '7. Unknown skill leaves no partial destination' {
        $testRepo = Copy-TestRepository
        $destination = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'install.ps1') -Arguments @(
            '-Skills', 'not-a-real-skill', '-Destination', $destination
        )
        Assert-True ($result.ExitCode -ne 0) 'Unknown skill unexpectedly succeeded.'
        Assert-True (-not (Test-Path -LiteralPath $destination)) 'Unknown skill created a partial destination.'
    }

    Invoke-TestCase '8. WhatIf creates no files' {
        $testRepo = Copy-TestRepository
        $destination = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'install.ps1') -Arguments @(
            '-Skills', 'frontend-implementation', '-Destination', $destination, '-WhatIf'
        )
        Assert-Equal 0 $result.ExitCode "WhatIf failed. $($result.Output)"
        Assert-True (-not (Test-Path -LiteralPath $destination)) 'WhatIf created the destination.'
    }

    Invoke-TestCase '9. Doctor is healthy for a clean temp install' {
        $testRepo = Copy-TestRepository
        $destination = Install-AllToTemp -TestRepo $testRepo
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'doctor.ps1') -Arguments @('-SkillRoots', $destination, '-Json')
        Assert-Equal 0 $result.ExitCode "Doctor rejected a clean install. $($result.Output)"
        $json = ConvertFrom-DoctorJson -Result $result
        Assert-True ([bool]$json.summary.healthy) 'Doctor JSON did not mark the clean install healthy.'
    }

    Invoke-TestCase '10. Doctor finds a duplicate in a second root' {
        $testRepo = Copy-TestRepository
        $rootOne = Install-AllToTemp -TestRepo $testRepo
        $rootTwo = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $rootTwo -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $rootOne 'frontend-acceptance-review') -Destination (Join-Path $rootTwo 'frontend-acceptance-review') -Recurse
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'doctor.ps1') -Arguments @('-SkillRoots', "$rootOne,$rootTwo", '-Json')
        Assert-Equal 1 $result.ExitCode "Doctor did not fail for a duplicate. $($result.Output)"
        $json = ConvertFrom-DoctorJson -Result $result
        Assert-True (@($json.duplicates | Where-Object name -eq 'frontend-acceptance-review').Count -eq 1) 'Duplicate name was not reported.'
        Assert-True (@(($json.duplicates | Where-Object name -eq 'frontend-acceptance-review').paths).Count -eq 2) 'Duplicate paths were not both reported.'
    }

    Invoke-TestCase '11. Doctor finds changed, missing, and extra files' {
        $testRepo = Copy-TestRepository
        $destination = Install-AllToTemp -TestRepo $testRepo
        $skill = Join-Path $destination 'frontend-acceptance-review'
        [System.IO.File]::AppendAllText((Join-Path $skill 'agents\openai.yaml'), "# changed`r`n", $utf8NoBom)
        Remove-Item -LiteralPath (Join-Path $skill 'references\functional-checklist.md') -Force
        [System.IO.File]::WriteAllText((Join-Path $skill 'extra.txt'), 'extra', $utf8NoBom)
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'doctor.ps1') -Arguments @('-SkillRoots', $destination, '-Json')
        Assert-Equal 1 $result.ExitCode "Doctor did not fail for drift. $($result.Output)"
        $json = ConvertFrom-DoctorJson -Result $result
        $item = @($json.drift | Where-Object name -eq 'frontend-acceptance-review')[0]
        Assert-True ($null -ne $item) 'Drifted skill was not reported.'
        Assert-True (@($item.changed).Count -gt 0) 'Changed files were not reported.'
        Assert-True (@($item.missing).Count -gt 0) 'Missing files were not reported.'
        Assert-True (@($item.extra).Count -gt 0) 'Extra files were not reported.'
    }

    Invoke-TestCase '12. Doctor finds a missing required dependency' {
        $testRepo = Copy-TestRepository
        $destination = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
        $install = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'install.ps1') -Arguments @(
            '-Skills', 'frontend-design-planner', '-Destination', $destination
        )
        Assert-Equal 0 $install.ExitCode "Dependency test install failed. $($install.Output)"
        Remove-Item -LiteralPath (Join-Path $destination 'web-ui-designer') -Recurse -Force
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'doctor.ps1') -Arguments @('-SkillRoots', $destination, '-Json')
        Assert-Equal 1 $result.ExitCode "Doctor did not fail for a missing dependency. $($result.Output)"
        $json = ConvertFrom-DoctorJson -Result $result
        $issue = @($json.dependencies | Where-Object name -eq 'frontend-design-planner')[0]
        Assert-True ($null -ne $issue) 'Missing dependency issue was not reported.'
        Assert-True ('web-ui-designer' -in @($issue.missing)) 'Missing web-ui-designer dependency was not named.'
    }

    Invoke-TestCase '13. Doctor JSON exposes the stable contract sections' {
        $testRepo = Copy-TestRepository
        $destination = Install-AllToTemp -TestRepo $testRepo
        $result = Invoke-PackScript -ScriptPath (Join-Path $testRepo 'doctor.ps1') -Arguments @('-SkillRoots', $destination, '-Json')
        $json = ConvertFrom-DoctorJson -Result $result
        $properties = @($json.PSObject.Properties.Name)
        foreach ($section in @('summary', 'duplicates', 'drift', 'dependencies', 'references')) {
            Assert-True ($section -in $properties) "Doctor JSON is missing '$section'."
        }
    }

    Invoke-TestCase '14. Behavioral eval catalog and result contract validate' {
        $result = Invoke-PackScript -ScriptPath (Join-Path $repoRoot 'evals\validate-evals.ps1')
        Assert-Equal 0 $result.ExitCode "Behavioral eval catalog failed validation. $($result.Output)"
        Assert-True ($result.Output -match '20 scenarios') 'Eval validator did not report all 20 scenarios.'
        Assert-True ($result.Output -match 'NOT RUN=20') 'Current results must disclose that behavioral runs were not executed.'
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        $resolvedTempRoot = (Resolve-Path -LiteralPath $tempRoot).Path
        $expectedTempParent = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if ($resolvedTempRoot.StartsWith($expectedTempParent, [System.StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolvedTempRoot) -like 'frontend-codex-skills-tests-*') {
            Remove-Item -LiteralPath $resolvedTempRoot -Recurse -Force
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Error ("$($failures.Count) test(s) failed:`n- " + ($failures -join "`n- "))
    exit 1
}

Write-Host "All $passed integration tests passed." -ForegroundColor Green
