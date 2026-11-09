# Alat rilis SMART: bangun, periksa tanda tangan, hitung SHA-256, terbitkan ke GitHub Releases. Lihat RELEASING.md.
#
#   .\scripts\release.ps1 -Type patch|minor|big|major [-Mandatory|-Optional]
#   .\scripts\release.ps1 -Rollback -To 1.0.0 -Block 3 [-Version 1.0.2]
#   .\scripts\release.ps1 -Unpublish        # cabut rilis terbaru; rilis sebelumnya kembali menjadi yang terbaru
#   .\scripts\release.ps1 -PublishOnly      # terbitkan ulang build saat ini (APK sudah dibangun)
#
# Syarat: gh (GitHub CLI) sudah login, android/key.properties dan kunci rilis ada, flutter dan Android SDK terpasang.
param(
  [ValidateSet('patch', 'minor', 'big', 'major')][string]$Type,
  [switch]$Mandatory,
  [switch]$Optional,
  [switch]$Rollback,
  [string]$To,
  [int[]]$Block = @(),
  [string]$Version,
  [switch]$Unpublish,
  [switch]$PublishOnly,
  [switch]$Prerelease,
  [string]$ManifestOut,
  [string[]]$Abis = @('arm64', 'arm32'),   # hanya untuk uji emulator: -Abis x64
  [switch]$NoGit,
  [switch]$NoPush
)

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $Root
$Repo = 'Sadamdi/smart'
$ReleaseCert = (Get-Content (Join-Path $Root 'release-cert.sha256') -Raw).Trim().ToLower()

function Fail($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }
# git menulis kemajuan ke stderr; di Windows PowerShell itu dianggap galat fatal.
function Invoke-Quiet([scriptblock]$cmd) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { & $cmd 2>&1 | Out-Null } finally { $ErrorActionPreference = $prev }
}
function Tag-For([string]$name, [int]$build) { "app-v$name-b$build" }

# ---------------------------------------------------------------- cabut rilis
if ($Unpublish) {
  # Menghentikan distribusi build terbaru. Ponsel yang sudah memasangnya butuh rilis -Rollback (Android tidak bisa menurunkan build).
  $latest = gh release view --repo $Repo --json tagName -q .tagName 2>$null
  if (-not $latest) { Fail 'Tidak ada rilis untuk dicabut.' }
  gh release delete $latest --repo $Repo --yes --cleanup-tag
  Write-Host "==> $latest dicabut; rilis sebelumnya kembali menjadi yang terbaru."
  exit 0
}

# ---------------------------------------------------------------- versi
function Get-Pubspec {
  $line = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)').Matches[0]
  return @{ Major = [int]$line.Groups[1].Value; Minor = [int]$line.Groups[2].Value; Patch = [int]$line.Groups[3].Value; Build = [int]$line.Groups[4].Value }
}
function Set-Pubspec([string]$dir, [string]$name, [int]$build) {
  $p = Join-Path $dir 'pubspec.yaml'
  (Get-Content $p) -replace '^version:.*$', "version: $name+$build" | Set-Content $p -Encoding utf8
}

$cur = Get-Pubspec
$newBuild = $cur.Build + 1
$releaseType = $Type
if ($PublishOnly) {
  $newBuild = $cur.Build
  $newName = "$($cur.Major).$($cur.Minor).$($cur.Patch)"
  $releaseType = 'patch'
} elseif ($Rollback) {
  if (-not $To) { Fail '-Rollback butuh -To <versi stabil>, mis. -To 1.0.0' }
  $newName = if ($Version) { $Version } else { "$($cur.Major).$($cur.Minor).$($cur.Patch + 1)" }
  $releaseType = 'rollback'
} else {
  if (-not $Type) { Fail 'Pilih -Type patch|minor|big|major (lihat RELEASING.md)' }
  $newName = switch ($Type) {
    'patch' { "$($cur.Major).$($cur.Minor).$($cur.Patch + 1)" }
    'minor' { "$($cur.Major).$($cur.Minor + 1).0" }
    # "Rilis besar": lompat ke kelipatan .5 berikutnya (1.0 menjadi 1.5, 1.5 menjadi 2.0).
    'big'   { if ($cur.Minor -lt 5) { "$($cur.Major).5.0" } else { "$($cur.Major + 1).0.0" } }
    'major' { "$($cur.Major + 1).0.0" }
  }
  if ($Version) { $newName = $Version }
}

# ---------------------------------------------------------------- catatan rilis
$notesDir = Join-Path $Root 'release-notes'
New-Item -ItemType Directory -Force $notesDir | Out-Null
$notesFile = Join-Path $notesDir ('{0:D4}-{1}.md' -f $newBuild, $newName)
if (-not (Test-Path $notesFile)) {
  $defaultMandatory = if ($releaseType -eq 'major') { 'true' } else { 'false' }
  $blocks = if ($Block.Count) { "[$($Block -join ', ')]" } else { '[]' }
  @"
---
version: $newName
build: $newBuild
date: $(Get-Date -Format 'yyyy-MM-dd')
type: $releaseType
mandatory: $defaultMandatory
blocks: $blocks
---
Tulis catatan rilis untuk pengguna di sini (Bahasa Indonesia, tanpa istilah teknis).

Yang baru
- ...

Perbaikan
- ...
"@ | Set-Content $notesFile -Encoding utf8
  Fail "Catatan rilis belum ada. Template dibuat di $notesFile. Isi lalu jalankan ulang."
}
if ((Get-Content $notesFile -Raw) -match 'Tulis catatan rilis') { Fail "Isi dulu catatan rilis di $notesFile" }

function Read-Note([string]$path) {
  $raw = (Get-Content $path -Raw -Encoding utf8).TrimStart([char]0xFEFF)
  if ($raw -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)$') { Fail "Frontmatter rusak: $path" }
  $front = $Matches[1]
  $body = $Matches[2].Trim()
  $meta = @{}
  $front -split '\r?\n' | Where-Object { $_ -match '^(\w+):\s*(.*)$' } | ForEach-Object { $meta[$Matches[1]] = $Matches[2].Trim() }
  $blocks = @()
  if ($meta['blocks'] -match '\[(.*)\]') { $blocks = @($Matches[1] -split ',' | Where-Object { $_.Trim() } | ForEach-Object { [int]$_.Trim() }) }
  return [pscustomobject]@{
    version = $meta['version']; build = [int]$meta['build']; date = $meta['date']; type = $meta['type']
    mandatory = ($meta['mandatory'] -eq 'true'); blocks = $blocks; notes = $body
  }
}
$note = Read-Note $notesFile
if ($Mandatory) { $note.mandatory = $true }
if ($Optional) { $note.mandatory = $false }
Write-Host ("==> Rilis {0}+{1} ({2}), pembaruan {3}" -f $newName, $newBuild, $note.type, $(if ($note.mandatory) { 'WAJIB' } else { 'opsional' }))

# ---------------------------------------------------------------- build
$buildRoot = $Root
if ($Rollback) {
  $tag = (git tag --list "app-v$To-b*" | Select-Object -Last 1)
  if (-not $tag) { Fail "Tag untuk versi $To tidak ditemukan (app-v$To-bN)." }
  $buildRoot = Join-Path $Root 'build\rollback'
  if (Test-Path $buildRoot) { Invoke-Quiet { git worktree remove --force $buildRoot } }
  Invoke-Quiet { git worktree prune }
  Invoke-Quiet { git worktree add --detach $buildRoot $tag }
  if (-not (Test-Path (Join-Path $buildRoot 'pubspec.yaml'))) { Fail "Gagal menyiapkan kode $tag untuk rollback." }
  Copy-Item (Join-Path $Root 'android\key.properties') (Join-Path $buildRoot 'android\key.properties') -Force
  Write-Host "==> Rollback: membangun ulang kode $tag sebagai $newName+$newBuild"
}
$fileTag = "$newName-b$newBuild"
$apks = @{}
foreach ($abi in $Abis) { $apks[$abi] = Join-Path $buildRoot "releases\smart-$fileTag-$abi.apk" }
if (-not $PublishOnly) {
  Set-Pubspec $buildRoot $newName $newBuild
  & (Join-Path $buildRoot 'scripts\build_android_release.ps1') -Abis $Abis
  # Keberhasilan dinilai dari APK dan pemeriksaan tanda tangan di bawah, bukan dari $LASTEXITCODE.
}
$sdk = (Get-Content 'android\local.properties' | Where-Object { $_ -match '^sdk.dir=' }) -replace '^sdk.dir=', '' -replace '\\\\', '\' -replace '\\:', ':'
$apksigner = Get-ChildItem (Join-Path $sdk 'build-tools') -Directory | Sort-Object Name | Select-Object -Last 1 | ForEach-Object { Join-Path $_.FullName 'apksigner.bat' }
$sha = @{}
foreach ($abi in $Abis) {
  if (-not (Test-Path $apks[$abi])) { Fail "APK tidak ditemukan: $($apks[$abi])" }
  $certOut = (& $apksigner verify --print-certs $apks[$abi] | Select-String 'SHA-256') -replace '\s', ''
  if ("$certOut".ToLower() -notmatch $ReleaseCert) { Fail "APK $abi TIDAK ditandatangani kunci rilis. Periksa android/key.properties." }
  $sha[$abi] = (Get-FileHash $apks[$abi] -Algorithm SHA256).Hash.ToLower()
}
Write-Host '==> Tanda tangan dan SHA-256 OK'

# ---------------------------------------------------------------- manifest
$all = Get-ChildItem $notesDir -Filter '*.md' | ForEach-Object { Read-Note $_.FullName } | Sort-Object build
if ($note.build -notin $all.build) { $all += $note }
$mandatoryBuilds = @($all | Where-Object { $_.mandatory -and $_.build -le $newBuild } | ForEach-Object build)
$minBuild = if ($mandatoryBuilds.Count) { ($mandatoryBuilds | Measure-Object -Maximum).Maximum } else { 1 }
$blocked = @($all | ForEach-Object { $_.blocks } | Where-Object { $_ } | Sort-Object -Unique)
$newTag = Tag-For $newName $newBuild
$base = "https://github.com/$Repo/releases/download/$newTag"
$apkUrl = [ordered]@{}
foreach ($abi in $Abis) { $apkUrl[$abi] = "$base/smart-$fileTag-$abi.apk" }
$manifest = [ordered]@{
  version = $newName; build = $newBuild; minBuild = [int]$minBuild; blockedBuilds = $blocked
  # Dialog pembaruan hanya menampilkan paragraf pertama; catatan lengkap ada di riwayat.
  notes = ($note.notes -split '\r?\n\s*\r?\n')[0].Trim()
  apks = $apkUrl; sha256 = $sha; certSha256 = $ReleaseCert
  history = @($all | Sort-Object build -Descending | ForEach-Object {
      [ordered]@{ version = $_.version; build = $_.build; date = $_.date; type = $_.type; notes = $_.notes } })
}
$manifestPath = if ($ManifestOut) { $ManifestOut } else { Join-Path $Root 'build\latest.json' }
New-Item -ItemType Directory -Force (Split-Path $manifestPath) | Out-Null
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
# Aset harus bernama latest.json agar alamat tetap .../releases/latest/download/latest.json bekerja.
$manifestAsset = Join-Path (Split-Path $manifestPath) 'latest.json'
if ($manifestPath -ne $manifestAsset) { Copy-Item $manifestPath $manifestAsset -Force }

# ---------------------------------------------------------------- git (sebelum terbit, agar tag menunjuk commit yang ada di GitHub)
if ($Rollback) { Invoke-Quiet { git worktree remove --force $buildRoot } }
if (-not $PublishOnly) { Set-Pubspec $Root $newName $newBuild }
if ($NoGit) {
  # Uji coba: tidak membuat commit; tag menunjuk ujung cabang main yang sudah ada di GitHub.
  $sha1 = 'main'
} else {
  git add pubspec.yaml release-notes
  Invoke-Quiet { git commit -q -m "[chore] release $newName+$newBuild ($($note.type))" }
  if (-not $NoPush) { git push -q -u origin HEAD }
  $sha1 = (git rev-parse HEAD).Trim()
}

# ---------------------------------------------------------------- terbitkan
Write-Host '==> Menerbitkan ke GitHub Releases...'
$ghArgs = @('release', 'create', $newTag) + @($Abis | ForEach-Object { $apks[$_] }) + @($manifestAsset, '--repo', $Repo,
  '--target', $sha1, '--title', "SMART $newName", '--notes', $note.notes)
if ($Prerelease) { $ghArgs += '--prerelease' } else { $ghArgs += '--latest' }
gh @ghArgs
if ($LASTEXITCODE -ne 0) { Fail 'gh release create gagal.' }
Write-Host "==> Selesai: $newName+$newBuild (tag $newTag)"
Write-Host "    Manifest: https://github.com/$Repo/releases/latest/download/latest.json"
