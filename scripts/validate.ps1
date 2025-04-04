#Validation of input, should be ran as first step

. "$PSScriptRoot\variables.ps1"



$buildGuid=[guid]::NewGuid()
Write-Host "Build GUID: $buildGuid"

Write-Host "##vso[task.setvariable variable=build.guid;]$buildGuid"


Write-Host "All env. variables:"

Get-ChildItem Env:

$allowed_BUILD_CONFIGURATION = "release"
$allowed_BUILD_PLATFORM = "x86","x64"
$allowed_BOOL = "true","false"


$Env:BUILD_CONFIGURATION=$Env:BUILD_CONFIGURATION.Trim();


$valError=0;

if ($Env:BUILD_CONFIGURATION -eq $null -or $allowed_BUILD_CONFIGURATION -notcontains $Env:BUILD_CONFIGURATION.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.Configuration: $Env:BUILD_CONFIGURATION";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.Configuration: $allowed_BUILD_CONFIGURATION";
   $valError=1;
}


if ($Env:BUILD_PLATFORM -eq $null -or $allowed_BUILD_PLATFORM -notcontains $Env:BUILD_PLATFORM.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.Platform: $Env:BUILD_PLATFORM";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.Platform: $allowed_BUILD_PLATFORM" ;
   $valError=1;
}



if ($Env:BUILD_EP_PRODUCT -eq $null -or $allowed_BOOL -notcontains $Env:BUILD_EP_PRODUCT.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.EP_PRODUCT: $Env:BUILD_EP_PRODUCT";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.EP_PRODUCT: $allowed_BOOL" ;
   $valError=1;
}



if ($Env:BUILD_ALLLANGS -eq $null) {

    Write-Host "##vso[task.setvariable variable=build.AllLangs;]false"
}
elseif ($allowed_BOOL -notcontains $Env:BUILD_ALLLANGS.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.AllLangs: $Env:BUILD_ALLLANGS";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.AllLangs: $allowed_BOOL" ;
   $valError=1;
}



if ($Env:BUILD_CHECKFORMS -eq $null) {

    Write-Host "##vso[task.setvariable variable=build.CheckForms;]false"
}
elseif ($allowed_BOOL -notcontains $Env:BUILD_CHECKFORMS.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.CheckForms: $Env:BUILD_CHECKFORMS";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.CheckForms: $allowed_BOOL" ;
   $valError=1;
}


if ($Env:BUILD_NATIVECODEANALYSIS -eq $null) {

    Write-Host "##vso[task.setvariable variable=build.NativeCodeAnalysis;]false"
}
elseif ($allowed_BOOL -notcontains $Env:BUILD_NATIVECODEANALYSIS.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.NativeCodeAnalysis: $Env:BUILD_NATIVECODEANALYSIS";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.NativeCodeAnalysis: $allowed_BOOL" ;
   $valError=1;
}


if ($Env:BUILD_NATIVECODEANALYSIS -eq "true" -and !(Test-Path "$Env:BUILD_SOURCESDIRECTORY\BuildEnv\NativeCodeAnalysis_Enable.bat")) {
	Write-Host "This source branch doesn't support NativeCodeAnalysis" ;
	Write-Host "##vso[task.setvariable variable=build.NativeCodeAnalysis;]false"
}


if (($Env:BUILD_SKIPPOIROTS -eq $null) -or ($Env:BUILD_SKIPPOIROTS  -eq "")) {
    
    if ($isTriggerOnlyBuild) {
        Write-Host "##vso[task.setvariable variable=build.SkipPoirots;]default"
    }
    else {
        Write-Host "##vso[task.setvariable variable=build.SkipPoirots;]false"
    }
}
elseif ($allowed_BOOL -notcontains $Env:BUILD_SKIPPOIROTS.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.SkipPoirots: $Env:BUILD_SKIPPOIROTS";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.SkipPoirots: $allowed_BOOL" ;
   $valError=1;
}


if ($Env:BUILD_SKIPUNITTESTS -eq $null) {

    Write-Host "##vso[task.setvariable variable=build.SkipUnitTests;]false"
}
elseif ($allowed_BOOL -notcontains $Env:BUILD_SKIPUNITTESTS.ToLower()) {
   Write-Host "##vso[task.logissue type=error]Invalid value for Build.SkipUnitTests: $Env:BUILD_SKIPUNITTESTS";
   Write-Host "##vso[task.logissue type=error]Valid values for Build.SkipUnitTests: $allowed_BOOL" ;
   $valError=1;
}




if ($Env:BUILD_ALLLANGS.ToLower() -eq "true" -and $Env:BUILD_CHECKFORMS.ToLower() -eq "true") {

    Write-Host "Check forms build is not necessary with all langs build and was disabled!";
    Write-Host "##vso[task.setvariable variable=build.CheckForms;]false";
}


if ($Env:BUILD_PLATFORM -eq "x64" -and !(Test-Path "$Env:BUILD_SOURCESDIRECTORY\A\_ConfigBuilder\BuildAll_Server64.bat")) {
  Write-Host "##vso[task.logissue type=error]This source branch doesn't support x64 build" ;
   $valError=1;
}


if ($Env:BUILD_POIROTREVISION -ne $null -and $Env:BUILD_POIROTREVISION -ne "") {

    if (($Env:BUILD_POIROTREVISION -match "^\d+$") -eq $false) {
        Write-Host "##vso[task.logissue type=error]PoirotRevision $($Env:BUILD_POIROTREVISION) is not valid! It must be positive integer number. Or leave it blank for HEAD revision" ;
        $valError=1;
    }

}


if (($Env:BUILD_SYNCBUILD -eq "true") -and ($Env:BUILD_QUEUEDBYID -ne $buildServiceId)) {

	Write-Host "Sync build was ran manually, so it's not actually sync build => will be run as normal build"

	
}

Exit $valError;
