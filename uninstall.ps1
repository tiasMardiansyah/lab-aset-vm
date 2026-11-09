#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$hostsFile = "$env:WINDIR\System32\drivers\etc\hosts"
$begin = '# >>> lab-aset-vm >>>'
$end = '# <<< lab-aset-vm <<<'

$lines = Get-Content $hostsFile
$out = New-Object System.Collections.Generic.List[string]
$skip = $false
$removed = $false
foreach ($line in $lines) {
    if ($line -eq $begin) { $skip = $true; $removed = $true; continue }
    if ($line -eq $end) { $skip = $false; continue }
    if (-not $skip) { $out.Add($line) }
}

if ($removed) {
    Set-Content -Path $hostsFile -Value $out -Encoding ASCII
    ipconfig /flushdns | Out-Null
    Write-Host 'Entri lab-aset-vm dihapus dari hosts.' -ForegroundColor Green
} else {
    Write-Host 'Tidak ada entri lab-aset-vm di hosts — tidak ada yang dihapus.' -ForegroundColor Yellow
}
