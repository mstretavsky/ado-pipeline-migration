. "$PSScriptRoot\variables.ps1"


$Env:BUILD_ESAVERSION| Out-File $OutputInstallDir\esa.ver -Encoding ascii


$Env:BUILD_SOURCEBRANCH | Out-File  $OutputInstallDir\compiled_branch.txt -Encoding ascii -ErrorAction SilentlyContinue
$Env:BUILD_SOURCEVERSION | Out-File  $OutputInstallDir\compiled_revision.txt -Encoding ascii -ErrorAction SilentlyContinue

dir $OutputDir\*_09.dll| Foreach-Object{
 if (Test-Path $_) {
copy-item -path $_ -destination $OutputInstallDir -Recurse -Container -PassThru -Force}
}


Get-Content $PSScriptRoot\postbuild\esa_files.txt| Foreach-Object{
 if (Test-Path $OutputDir\$_) {
copy-item -path $OutputDir\$_ -destination $OutputInstallDir -Recurse -Container -PassThru -Force}
}


Write-Host "Signing exe files..."

$SignSourceRoot="$ScriptWorkRoot\signsource";

New-Item -ItemType Directory -Force -Path $SignSourceRoot
Remove-Item "$SignSourceRoot\*" -Recurse



if (Test-Path $OutputInstallDir\Esa.exe) {
	copy $OutputInstallDir\Esa.exe $SignSourceRoot
}

if (Test-Path $OutputInstallDir\EsaL.exe) {
	copy $OutputInstallDir\EsaL.exe $SignSourceRoot
}

if (Test-Path $OutputInstallDir\SciaEngineer.exe) {
	copy $OutputInstallDir\SciaEngineer.exe $SignSourceRoot
}

if (Test-Path $OutputInstallDir\UIComponentCatalog.exe) {
	copy $OutputInstallDir\UIComponentCatalog.exe $SignSourceRoot
}

& $PSScriptRoot\postbuild\signfiles\signfiles.cmd $SignSourceRoot

copy $SignSourceRoot\_signed\*.* $OutputInstallDir\ -Force


Write-Host "Generating protection..."
pushd  $PSScriptRoot\postbuild\gendat
& $PSScriptRoot\postbuild\gendat\gendat.bat
popd

Write-Host "Hacking A_P.regSYS.bat..."
$AP_regSYS_file="$OutputInstallDir\A_P.regSYS.bat"
$AP_regSYS_md5_orig="a9b9b282be8ddd58484a1e1d09c08ab0"

if (Test-Path $AP_regSYS_file) {
	$AP_regSYS_md5 = & $PSScriptRoot\postbuild\md5.exe -l -n $AP_regSYS_file
	
	Write-Host "A_P.regSYS.bat MD5: $AP_regSYS_md5"
	Write-Host " - should be: $AP_regSYS_md5_orig"

	if ($AP_regSYS_md5 -eq $AP_regSYS_md5_orig) {
		Write-Host "Copy altered A_P.regSYS.bat to Install folder"
		copy $PSScriptRoot\postbuild\A_P.regSYS.bat $OutputInstallDir\ -Force
	}
	

}


Write-Host "Registering files..."
pushd $OutputInstallDir
(Get-Content $AP_reg_file) | ForEach-Object { $_ -replace "call EP_OpenCheckDbBuilder.exe", "" } | ForEach-Object { $_ -replace "call XEP_StringCodeGenerator.exe", "" } | Set-Content $AP_reg_file

& $AP_reg_file 2>$null
popd


Write-Host "Done."
Exit 0
