Write-Host "Killing processes..."
Get-Content $PSScriptRoot\postbuild\kill_process.txt| Foreach-Object {
    Get-Process | Where ProcessName -eq  $_ | Stop-Process -Force -PassThru
 }

Write-Host "Running processes..."
Get-Process | Select-Object ProcessName | Format-Table


Write-Host "Delete ESA folder and registry"


$esaVersion= $Env:BUILD_ESAVERSION;

$regVersion= $esaVersion.Substring(0,4);
Write-Host "Registry version: $regVersion";

$esaDir= $Env:USERPROFILE + "\ESA" + $regVersion;

Write-Host "ESA folder: $esaDir";
if (Test-Path -Path $esaDir -PathType Container) {
    Write-Host "Delete ESA folder $esaDir";
    Remove-Item -Path $esaDir -Recurse -Force;
}

$esaRegPath="HKCU:\Software\SCIA\Esa\$regVersion"

Write-Host "Registry path: $esaRegPath";
if (Test-Path -Path $esaRegPath -PathType Container) {
    Write-Host "Delete registry key $esaRegPath";
    Remove-Item -Path $esaRegPath -Recurse -Force;
}

Write-Host "Done."