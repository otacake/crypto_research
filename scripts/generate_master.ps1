param(
  [string]$ChaptersDir = "docs/manuscript/chapters",
  [string]$SourcesFile = "docs/references/sources.yaml",
  [string]$ResearchBacklogFile = "ops/research_backlog.md",
  [string]$OutputFile = "docs/manuscript/master.md"
)

$ErrorActionPreference = "Stop"

function Parse-SourcesYaml {
  param([string]$Path)

  $map = @{}
  if (-not (Test-Path $Path)) {
    return $map
  }

  $lines = Get-Content -Encoding utf8 $Path
  $inSources = $false
  $current = $null

  foreach ($line in $lines) {
    if (-not $inSources -and $line -match "^\s*sources:\s*$") {
      $inSources = $true
      continue
    }
    if (-not $inSources) {
      continue
    }

    if ($line -match '^\s*-\s+chapter:\s*"[^"]*"\s*$') {
      if ($null -ne $current -and $current.source_id) {
        $map[$current.source_id] = [pscustomobject]$current
      }
      $current = @{
        source_id     = ""
        title         = ""
        url           = ""
        year          = ""
        organization  = ""
        authors       = @()
      }
      continue
    }

    if ($null -eq $current) {
      continue
    }

    if ($line -match '^\s*source_id:\s*"([^"]+)"\s*$') {
      $current.source_id = $matches[1]
      continue
    }
    if ($line -match '^\s*title:\s*"([^"]+)"\s*$') {
      $current.title = $matches[1]
      continue
    }
    if ($line -match '^\s*url:\s*"([^"]+)"\s*$') {
      $current.url = $matches[1]
      continue
    }
    if ($line -match '^\s*year:\s*(\d{4})\s*$') {
      $current.year = $matches[1]
      continue
    }
    if ($line -match '^\s*publication_date:\s*"([^"]+)"\s*$') {
      $current.year = ($matches[1] -split "-")[0]
      continue
    }
    if ($line -match '^\s*organization:\s*"([^"]+)"\s*$') {
      $current.organization = $matches[1]
      continue
    }
    if ($line -match '^\s*authors:\s*\[(.*)\]\s*$') {
      $raw = $matches[1].Trim()
      if ($raw.Length -eq 0) {
        $current.authors = @()
      } else {
        $current.authors = @(
          $raw -split "," |
          ForEach-Object { $_.Trim().Trim('"') } |
          Where-Object { $_ -ne "" }
        )
      }
      continue
    }
  }

  if ($null -ne $current -and $current.source_id) {
    $map[$current.source_id] = [pscustomobject]$current
  }

  return $map
}

function Parse-ResearchBacklog {
  param([string]$Path)

  $map = @{}
  if (-not (Test-Path $Path)) {
    return $map
  }

  $lines = Get-Content -Encoding utf8 $Path
  foreach ($line in $lines) {
    if ($line -match '^\|\s*(RB-\d{3})\s*\|\s*([^|]+)\|\s*([^|]+)\|') {
      $id = $matches[1]
      $chapter = $matches[2].Trim()
      $claim = $matches[3].Trim()
      $map[$id] = [pscustomobject]@{
        chapter = $chapter
        claim   = $claim
      }
    }
  }

  return $map
}

function Convert-CitationTagsToFootnotes {
  param([string]$Text)

  $converted = $Text
  $converted = [regex]::Replace(
    $converted,
    '\[(一次|二次):([A-Za-z0-9\-]+)\]',
    { param($m) "[^$($m.Groups[2].Value)]" }
  )
  $converted = [regex]::Replace(
    $converted,
    '\[要検証:(RB-\d{3})\]',
    { param($m) "[^$($m.Groups[1].Value)]" }
  )
  return $converted
}

function Remove-ChapterReferencesSection {
  param([string]$Text)

  # Remove per-chapter references block so master keeps a single consolidated references section.
  return [regex]::Replace(
    $Text,
    '(?ms)\r?\n## 参考文献\s*\r?\n[\s\S]*$',
    ''
  ).TrimEnd()
}

function Get-CitedIdsInOrder {
  param([string]$Text)

  $seen = [System.Collections.Generic.HashSet[string]]::new()
  $ordered = New-Object System.Collections.Generic.List[string]
  $matches = [regex]::Matches($Text, '\[\^([A-Za-z0-9\-]+)\]')
  foreach ($m in $matches) {
    $id = $m.Groups[1].Value
    if ($seen.Add($id)) {
      [void]$ordered.Add($id)
    }
  }
  return $ordered
}

$chapterFiles = Get-ChildItem -File $ChaptersDir -Filter "*.md" | Sort-Object Name
if ($chapterFiles.Count -eq 0) {
  throw "No chapter files found in $ChaptersDir"
}

$chapterBodies = foreach ($file in $chapterFiles) {
  $raw = Get-Content -Raw -Encoding utf8 $file.FullName
  Remove-ChapterReferencesSection -Text $raw
}
$masterBody = ($chapterBodies -join "`r`n`r`n").TrimEnd()
$masterBody = Convert-CitationTagsToFootnotes -Text $masterBody

$sourceMap = Parse-SourcesYaml -Path $SourcesFile
$rbMap = Parse-ResearchBacklog -Path $ResearchBacklogFile
$citedIds = Get-CitedIdsInOrder -Text $masterBody

$footnotes = New-Object System.Collections.Generic.List[string]
foreach ($id in $citedIds) {
  if ($sourceMap.ContainsKey($id)) {
    $src = $sourceMap[$id]
    $author = if ($src.authors.Count -gt 0) {
      ($src.authors -join ", ")
    } elseif ($src.organization) {
      $src.organization
    } else {
      "Unknown"
    }
    $year = if ($src.year) { $src.year } else { "n.d." }
    $title = if ($src.title) { $src.title } else { "(untitled)" }
    $url = if ($src.url) { $src.url } else { "" }
    [void]$footnotes.Add("[^$id]: $author ($year). $title. $url")
    continue
  }

  if ($id -match '^RB-\d{3}$') {
    if ($rbMap.ContainsKey($id)) {
      $rb = $rbMap[$id]
      [void]$footnotes.Add(("[^{0}]: 要検証。{1}の論点「{2}」。詳細は ops/research_backlog.md の {0} を参照。" -f $id, $rb.chapter, $rb.claim))
    } else {
      [void]$footnotes.Add(("[^{0}]: 要検証。詳細は ops/research_backlog.md を参照。" -f $id))
    }
    continue
  }

  [void]$footnotes.Add(("[^{0}]: 出典未解決。docs/references/sources.yaml に {0} を追加して再生成してください。" -f $id))
}

$masterText = $masterBody + "`r`n`r`n## 参考文献（脚注）`r`n`r`n" + ($footnotes -join "`r`n") + "`r`n"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutputFile, $masterText, $utf8NoBom)

Write-Host "Generated $OutputFile with footnote citations."

