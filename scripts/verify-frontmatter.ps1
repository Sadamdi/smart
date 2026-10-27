# Memeriksa tabel atribut pada dokumen teknis SMART.
# Pemakaian (dari folder SMART): powershell -ExecutionPolicy Bypass -File scripts\verify-frontmatter.ps1
# Keluar dengan kode 1 bila ada berkas yang tidak lengkap.

$akar = Split-Path -Parent $PSScriptRoot
$wajib = @('Versi', 'Tanggal', 'Status', 'Author', 'Sumber bisnis')
$wajibTodo = $wajib + @('Module', 'Priority', 'Progress', 'Last Updated')
$wajibVersion = $wajib + @('Tipe', 'Module', 'Branch', 'Last Updated')

$berkas = @()
$berkas += Get-ChildItem (Join-Path $akar 'Dokument') -Recurse -Filter *.md
$berkas += Get-ChildItem (Join-Path $akar 'apps\docs') -Recurse -Filter *.md

$gagal = 0
foreach ($b in $berkas) {
    $nama = $b.Name
    $rel = $b.FullName.Substring($akar.Length + 1)
    # Lewati README, indeks, templat, dan contoh akun
    if ($nama -like 'README*' -or $nama -like '*_INDEX.md' -or $nama -like '_*' -or $nama -like 'TESTING_ACCOUNTS*') { continue }
    if ($rel -like 'Dokument\local\*') { continue }

    $isi = Get-Content $b.FullName -Raw -Encoding UTF8
    $perlu = $wajib
    if ($rel -like 'apps\docs\todo\*') { $perlu = $wajibTodo }
    elseif ($rel -like 'apps\docs\version\*') { $perlu = $wajibVersion }

    $hilang = @()
    foreach ($k in $perlu) {
        if ($isi -notmatch ('\|\s*\*\*' + [regex]::Escape($k) + '\*\*\s*\|')) { $hilang += $k }
    }
    if ($hilang.Count -gt 0) {
        Write-Host ("GAGAL  {0}: tidak ada {1}" -f $rel, ($hilang -join ', '))
        $gagal++
    }
}

if ($gagal -gt 0) {
    Write-Host ("`n{0} berkas belum lengkap." -f $gagal)
    exit 1
}
Write-Host ("Semua {0} berkas memenuhi tabel atribut." -f ($berkas.Count))
