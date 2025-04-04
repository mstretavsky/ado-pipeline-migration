#Translation and compilation of SDF Forms

. "$PSScriptRoot\variables.ps1"


chcp

if ([System.Environment]::OSVersion.Version.Major -eq 6) {
	chcp 852
	chcp
}


Write-Host "****************************************************"
if ($Env:BUILD_USEGITTSM -eq $true) {
	Write-Host "Using translation memory from git sources"
}
else {
	Write-Host "Using translation memory from SVN repository"
}
Write-Host "****************************************************"


$SelectedLangsFile="$PSScriptRoot\postbuild\Langs_list.txt"

if ($Env:BUILD_USESCRIPTRCTRANSLATION -eq $true)
{
    Write-Host "Translate SDF languages with Python script"


	if ($Env:BUILD_ALLLANGS -eq "true") {
	Write-Host "Translate SDF C# projects"
    . $PSScriptRoot\postbuild\translateResXfiles.ps1 $SelectedLangsFile $BuildRoot "$PSScriptRoot\pack\7za.exe" "$PSScriptRoot\postbuild\translationTools" true $Env:BUILD_USEAZURETSM
	}


	Write-Host "Translate SDF Templates"
	. $PSScriptRoot\postbuild\translateCLSfiles.ps1 $Env:BUILD_ALLLANGS $BuildRoot "$PSScriptRoot\pack\7za.exe" "$PSScriptRoot\postbuild\translationTools" $BuildRoot\SDF_templates $Env:BUILD_USEAZURETSM


	Push-Location "$BuildRoot\SDF_templates"



	[string[]]$statsLines = Get-Content -Path 'MissingCLCs_stats.ini'

	$totalCls=$statsLines[1].split('=')[1]
	$failedCls=$statsLines[2].split('=')[1]


	Write-Host "Total CLS: $totalCls"
	Write-Host "Failed CLS: $failedCls"

	Pop-Location

	Invoke-SqlCmd -query "INSERT INTO SdfBuild (tfsBuildGuid,compilerErrorLog,clsFilesTotal,clsFilesFailedCompilation,dateCreated,languageBuild)
	VALUES ('$($Env:BUILD_GUID)','All forms were compiled successfully',$totalCls,$failedCls,GETDATE(),1)" -ServerInstance $dbServer -username $dbUserName -password $dbPassword -Database $dbDatabase

	
	if ($Env:BUILD_ALLLANGS -eq "true") {
		Write-Host "Translate SDF single languages"
		. $PSScriptRoot\postbuild\translateCLSfilesSingleLang.ps1 $BuildRoot "$PSScriptRoot\postbuild\translationTools" $BuildRoot\SDF_templates
	}

	
	if ($failedCls -gt 0) {
		Write-Host "##vso[task.logissue type=error]There were errors during CLS compilation, check the log";
		Exit 1
	}

}
else {


	Write-host "**** SDF Translation with RCMaker *****"
	Write-Host "Prepare workfolder"
	$sdfLangsWorkRoot = "$ScriptWorkRoot\SDF";

	New-Item $sdfLangsWorkRoot -ItemType Directory -Force
	Copy-Item -Path $PSSCriptRoot\languages\SDF\* $sdfLangsWorkRoot -Recurse -Force


	$scriptFiles = Get-ChildItem $sdfLangsWorkRoot\Translations\*.txt,$sdfLangsWorkRoot\bin\*.config -Recurse

	PrepareLangsWork $scriptFiles $sdfLangsWorkRoot;


	Push-Location $sdfLangsWorkRoot
	& $sdfLangsWorkRoot\SDFPostbuild.cmd  $ENV:BUILD_SOURCEBRANCHNAME $Env:BUILD_ESAVERSION xxx
	$visBuildExitCode = $LASTEXITCODE
	Pop-Location


	if ($visBuildExitCode -gt 0) {
		Write-Host "Visual build ExitCode: $visBuildExitCode"
		Write-Host "##vso[task.logissue type=error]SDF Postbuild step failed, errors during CLS translation";

		Exit $visBuildExitCode                                                      
	}
}
Write-Host "Done."
Exit 0
