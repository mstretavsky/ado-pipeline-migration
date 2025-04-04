. "$PSScriptRoot\variables.ps1"
Write-Host "Starting build..."

git status

if ($Env:BUILD_PLATFORM -eq "x64") {
    $Env:USEX64BUILD = "YES";
}

cd $BuildRoot\a\_ConfigBuilder


if ((Test-Path $BuildRoot\TempBuild) -eq $false) {
    md -Path $BuildRoot\TempBuild\
}

$tempBack = $Env:TEMP

$Env:TEMP="$BuildRoot\TempBuild"
$Env:TMP="$BuildRoot\TempBuild"

cmd.exe /c 'BuildAll_Server_main.bat' /rebuild 2>$null
$buildExitCode=$LASTEXITCODE

Write-Host "Build error level: $buildExitCode"

$Env:TEMP=$tempBack
$Env:TMP=$tempBack



#ConfigBuilder returns 1 if there are warnings, but script should return 0
if ($buildExitCode -eq 1) {
    $buildExitCode = 0
}

if ($buildExitCode -eq 0) {
	
	if ($Env:BUILD_PLATFORM -eq "x64") {
		$testExe="SciaEngineer.exe"
	}
	else {
		$testExe="esa.exe"
	}
	
	Write-Host "Check if $testExe exists..."
	if ((Test-Path "$OutputInstallDir\$testExe") -eq $false) {
		
		Write-Host "##vso[task.logissue type=error]$testExe doesn't exist, build probably failed, although it's reported by ConfigBuilder as succeeded!"
		$buildExitCode=2
		
	}
	else {
		Write-Host "$testExe exists"
	}
}

if ($buildExitCode -ne 0) {
    
    Write-Host "Full build log:"
    Get-Content $BuildRoot\a\Out\ConfigBuild\ESA_Build__All_BuildLog.txt

    $buildErrors = & $PSScriptRoot\postbuild\ParseBuildLog.exe $BuildRoot\a\Out\ConfigBuild\ESA_Build__All_BuildLog.txt -errors


   
    $arrBuildErrors = $buildErrors.Split(“`n”)
    $arrBuildErrors | ForEach-Object {
        if ($_ -ne "")   {
            Write-Host "##vso[task.logissue type=error]$_";
       }
    }

}

git status

Exit $buildExitCode
