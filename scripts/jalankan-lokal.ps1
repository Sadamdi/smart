# Menyiapkan (sekali) dan menjalankan SMART di laptop: backend di :8000 dan web di :3000.
# Pemakaian (dari folder SMART):
#   powershell -ExecutionPolicy Bypass -File scripts\jalankan-lokal.ps1            # siapkan bila perlu lalu jalankan
#   powershell -ExecutionPolicy Bypass -File scripts\jalankan-lokal.ps1 -Demo      # tambah data demo (berawalan [DEMO])
#   powershell -ExecutionPolicy Bypass -File scripts\jalankan-lokal.ps1 -Berhenti  # hentikan keduanya
# Catatan: basis data tetap Supabase (butuh internet). Alamat dan kata sandi ada di apps\backend\.env (tidak masuk git).
param([switch]$Demo, [switch]$Berhenti)
$ErrorActionPreference = "Stop"
$akar = Split-Path -Parent $PSScriptRoot
$be = Join-Path $akar "apps\backend"
$web = Join-Path $akar "apps\web"

if ($Berhenti) {
    foreach ($p in 8000, 3000) {
        Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue |
            ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "Backend dan web dihentikan."
    exit 0
}

foreach ($alat in "uv", "node", "npm") {
    if (-not (Get-Command $alat -ErrorAction SilentlyContinue)) { throw "$alat belum terpasang. Lihat apps\README.md." }
}
if (-not (Test-Path (Join-Path $be ".env"))) {
    Copy-Item (Join-Path $be ".env.example") (Join-Path $be ".env")
    throw "Isi DATABASE_URL dan JWT_SECRET di apps\backend\.env, lalu jalankan skrip ini lagi."
}
if (-not (Test-Path (Join-Path $web ".env.local"))) {
    "NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1" | Set-Content (Join-Path $web ".env.local") -Encoding utf8
}

Push-Location $be; uv sync --python 3.12; Pop-Location
Push-Location $web; npm install --no-audit --no-fund; Pop-Location

if ($Demo) { Push-Location $be; uv run python -m scripts.seed_demo --konfirmasi; Pop-Location }

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$be'; uv run uvicorn app.main:app --port 8000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$web'; npm run dev"
Write-Host ""
Write-Host "Web      : http://localhost:3000"
Write-Host "Backend  : http://localhost:8000/docs (Swagger)"
Write-Host "Akun demo: Dokument\local\AKUN-DEMO.md (bila memakai -Demo)"
