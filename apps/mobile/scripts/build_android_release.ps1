# Membangun APK rilis SMART per arsitektur CPU (lebih ringan dari APK universal).
# Keluaran: releases/smart-{versi}-arm64.apk (64-bit) dan releases/smart-{versi}-arm32.apk (32-bit lama)
param(
  [string]$ApiBaseUrl = "",
  # Hanya untuk uji di emulator: -Abis x64. Rilis sungguhan memakai bawaan (arm64 dan arm32).
  [string[]]$Abis = @("arm64", "arm32")
)

$ErrorActionPreference = "Stop"
# flutter menulis peringatan (mis. kunci startup) ke stderr; itu bukan galat. Kegagalan dicek lewat $LASTEXITCODE.
function Jalankan([scriptblock]$cmd) { $p = $ErrorActionPreference; $ErrorActionPreference = "Continue"; try { & $cmd 2>&1 | ForEach-Object { "$_" } } finally { $ErrorActionPreference = $p } }
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

$envFile = Join-Path $Root "build\android-release.env"
if (-not $ApiBaseUrl -and (Test-Path $envFile)) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^API_BASE_URL=(.+)$') { $ApiBaseUrl = $Matches[1].Trim() }
  }
}
if (-not $ApiBaseUrl) { $ApiBaseUrl = "https://smart-web-three.vercel.app/backend/api/v1" }
# Hanya untuk uji pembaruan: alamat manifest selain GitHub Releases rilis terbaru.
$ManifestUrl = ""
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object { if ($_ -match '^UPDATE_MANIFEST_URL=(.+)$') { $ManifestUrl = $Matches[1].Trim() } }
}
$manifestDefine = if ($ManifestUrl) { "--dart-define=UPDATE_MANIFEST_URL=$ManifestUrl" } else { "--dart-define=UPDATE_MANIFEST_URL=https://github.com/Sadamdi/smart/releases/latest/download/latest.json" }

if (-not (Test-Path (Join-Path $Root "android\key.properties"))) {
  throw "android/key.properties tidak ada: APK akan ditandatangani kunci debug dan tidak bisa menerima pembaruan resmi."
}

$versionFull = (Select-String -Path (Join-Path $Root "pubspec.yaml") -Pattern '^version:\s*(.+)$').Matches.Groups[1].Value.Trim()
$version = $versionFull -replace '\+', '-b'   # nama berkas aman: 1.0.1+2 menjadi 1.0.1-b2
$releasesDir = Join-Path $Root "releases"
New-Item -ItemType Directory -Force -Path $releasesDir | Out-Null
$define = "API_BASE_URL=$ApiBaseUrl"

Write-Host "==> SMART $versionFull | API: $ApiBaseUrl"
Jalankan { flutter pub get }
if ($LASTEXITCODE -ne 0) { throw "flutter pub get gagal" }

$targets = @{ arm64 = "android-arm64"; arm32 = "android-arm"; x64 = "android-x64" }
foreach ($abi in $Abis) {
  $t = @{ Target = $targets[$abi]; Name = $abi }
  Write-Host "==> Build $($t.Name)"
  Jalankan { flutter build apk --release --target-platform $t.Target --dart-define=$define $manifestDefine }
  if ($LASTEXITCODE -ne 0) { throw "flutter build $($t.Name) gagal" }
  Copy-Item (Join-Path $Root "build\app\outputs\flutter-apk\app-release.apk") (Join-Path $releasesDir "smart-$version-$($t.Name).apk") -Force
}
Write-Host "==> Selesai. arm64 untuk kebanyakan ponsel 2018 ke atas, arm32 untuk ponsel Android 32-bit lama."
