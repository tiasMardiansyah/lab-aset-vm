#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$ip = '192.168.56.10'
$domains = 'aset', 'www', 'api', 'mail', 'dev', 'backup', 'vpn', 'staging'
$hostsFile = "$env:WINDIR\System32\drivers\etc\hosts"
$begin = '# >>> lab-aset-vm >>>'
$end = '# <<< lab-aset-vm <<<'

$lines = Get-Content $hostsFile
$out = New-Object System.Collections.Generic.List[string]
$skip = $false
foreach ($line in $lines) {
    if ($line -eq $begin) { $skip = $true; continue }
    if ($line -eq $end) { $skip = $false; continue }
    if (-not $skip) { $out.Add($line) }
}

$out.Add('')
$out.Add($begin)
foreach ($d in $domains) { $out.Add("$ip`t$d.lab.local") }
$out.Add($end)

Set-Content -Path $hostsFile -Value $out -Encoding ASCII
ipconfig /flushdns | Out-Null

Write-Host ''
Write-Host 'Hosts entries ditambahkan:' -ForegroundColor Green
foreach ($d in $domains) { Write-Host "  $ip  $d.lab.local" }
Write-Host ''
Write-Host 'Jalankan: vagrant up' -ForegroundColor Cyan
