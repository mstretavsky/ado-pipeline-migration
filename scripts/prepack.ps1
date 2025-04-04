#Pre-packing steps

. "$PSScriptRoot\variables.ps1"

Write-Host "Running $($MyInvocation.MyCommand.Name)..."

if (Test-Path $OutputInstallDir\SciaEngineer.exe) {
	
	if (Test-Path $OutputInstallDir\Configuration\ApplicationConstants.xml) {
		. $PSScriptRoot\postbuild\writeSenVersionToUserSettings.ps1  "$OutputInstallDir\Configuration\ApplicationConstants.xml" $Env:BUILD_ESAVERSION "settings"
	}
	else {
		. $PSScriptRoot\postbuild\writeSenVersionToUserSettings.ps1  "$OutputInstallDir\Configuration\UserSettings.xml" $Env:BUILD_ESAVERSION "user_settings"
	}
}


if (Test-Path "$OutputInstallDir\solv_US.dll") {
    copy $OutputInstallDir\solv_US.dll $OutputInstallDir\Solv64_US.dll
}

if (Test-Path "$OutputInstallDir\esa_09.dll") {
	copy $OutputInstallDir\esa_09.dll $OutputInstallDir\esaL_09.dll
}

if (Test-Path "$OutputInstallDir\esa.dat") {
	copy $OutputInstallDir\esa.dat $OutputInstallDir\esaL.dat
}

copy $PSScriptRoot\postbuild\Licence\*.* $OutputInstallDir\Licence

del  $OutputInstallDir\*._i_ -Force



Get-Content $PSScriptRoot\postbuild\delete_files.txt| Foreach-Object{
    if (Test-Path -LiteralPath "$OutputInstallDir$_")
    {
        write-host "Delete $OutputInstallDir$_"
        remove-item -LiteralPath "$OutputInstallDir$_" -Force
    }
}


if ($Env:BUILD_PLATFORM -eq "x64") {

    Get-Content $PSScriptRoot\postbuild\delete_files_x64.txt| Foreach-Object{
        if (Test-Path -LiteralPath "$OutputInstallDir$_")
        {
            write-host "Delete $OutputInstallDir$_"
            remove-item -LiteralPath "$OutputInstallDir$_" -Force
        }
    }
}

Write-Host "Copy build log to 7z.."
copy $BuildRoot\a\Out\ConfigBuild\*.txt $OutputInstallDir

pushd $OutputInstallDir
attrib +R ESAAtl80_modules.Classes
attrib +R ESAAtl80_modules.ERG 
attrib +R ESAAtl80_modules.txt 
attrib +R ESAAtl80MBCS_modules.Classes 
attrib +R ESAAtl80MBCS_modules.ERG 
attrib +R ESAAtl80MBCS_modules.txt 
popd


Write-Host "Get number of warnigs...";

$warningsA = & $PSScriptRoot\postbuild\ParseBuildLog.exe $OutputInstallDir\ESA_Build__All_BuildLog.txt

Write-Host "Warnings A: $warningsA";
if ($warningsA -match "^[\d\.]+$") {
    Write-Host "##vso[task.setvariable variable=build.warningsA;]$warningsA";
}


if ($Env:BUILD_PLATFORM -eq "x86") {

    $warningsX = & $PSScriptRoot\postbuild\ParseBuildLog.exe $OutputInstallDir\Nexis_Build_All_BuildLog.txt

    Write-Host "Warnings X: $warningsX";
    if ($warningsX -match "^[\d\.]+$") {
        Write-Host "##vso[task.setvariable variable=build.warningsX;]$warningsX";
    }

}


Write-Host "##vso[task.setvariable variable=Build.CompilationFinished;]$true";



Write-Host "Done."