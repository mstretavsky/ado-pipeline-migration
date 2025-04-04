. "$PSScriptRoot\variables.ps1"

Write-Host Current Path: $PSScriptRoot

$PSVersionTable


#TEMP: Copy nuget config for TFS / Devops
$cadsFile="$($Env:BUILD_SOURCESDIRECTORY)\A\CADS\NuGet.Config"

Write-Host "CADS file: $cadsFile"
if ((Test-Path $cadsFile) -and ((Get-Content -Raw $cadsFile).Contains("tfssrv"))) {
  Write-Host "Copy TFS nuget config"
  Copy-Item "$PSScriptRoot\nuget\NuGet.Config.TFS" "$($Env:APPDATA)\NuGet\NuGet.Config"
}
else {
  Write-Host "Copy Devops nuget config"
  Copy-Item "$PSScriptRoot\nuget\NuGet.Config.DevOps" "$($Env:APPDATA)\NuGet\NuGet.Config"
}




#OutputPaths
$repoName=$Env:BUILD_REPOSITORY_NAME;
$pathSuffix="";

if ($repoName -ne "SEN") {

    if ($repoName -like "SEN.*") {
    
        $pathSuffix= "_" + $repoName.Replace("SEN.","");
    } 
    else {
        $pathSuffix="_" + $repoName;
    }


}

$OutputFtpPath=$OutputFtpPath.Replace("{suffix}",$pathSuffix);

$OutputFtpUTPath=$OutputFtpUTPath.Replace("{suffix}",$pathSuffix);

Write-Host "OutputFtpPath: $OutputFtpPath";
Write-Host "OutputFtpUTPath: $OutputFtpUTPath";



$builderName=$Env:COMPUTERNAME.Substring($Env:COMPUTERNAME.get_Length()-1)
Write-Host "##vso[task.setvariable variable=build.buildername;]$builderName";

if ($Env:BUILD_SOURCESDIRECTORY -eq $null) {
    Write-Error "BUILD_SOURCESDIRECTORY is null";
    Exit
}


#get major version
$srcPath=$Env:BUILD_SOURCEBRANCH    


if ($srcPath -eq $null) {
    Write-Host "##vso[task.logissue type=error]BUILD_SOURCEBRANCH is null!"
    Exit 1;
}


Write-Host "##vso[task.setvariable variable=build.SourceBranchReal;]$srcPath"

$srcPath=$srcPath.replace("refs/heads/","");
$srcPath=$srcPath.replace("refs/","");

if (($srcPath.StartsWith("tags/") -eq $false) -and ($srcPath.StartsWith("pull/") -eq $false) -and (Test-Path -Path $Env:BUILD_SOURCESDIRECTORY\.git)) {
    Write-Host "Check if commit belongs to selected branch"

    pushd $Env:BUILD_SOURCESDIRECTORY;

    git reset --hard HEAD
    git status

    $commitInBranches = & git branch --remote --no-color --contains $Env:BUILD_SOURCEVERSION;
    popd;
  

    $commitInBranches = $commitInBranches.Replace("origin/","");
    $arrCommitInBranches = $commitInBranches.Split("`r`n").Trim();

    Write-Host "Commit is in following branches:"
    $arrCommitInBranches

 
    if ($arrCommitInBranches.Contains($srcPath) -eq $false) {

        Write-Host "##vso[task.logissue type=error]Commit $Env:BUILD_SOURCEVERSION doesn't belong to GIT branch $srcPath! Use correct Commit ID or leave the Commit field empty";

        Exit 1;
    }
}


if (($Env:BUILD_COMMENT -eq $null -or $Env:BUILD_COMMENT -eq "") -and $Env:BUILD_SOURCEVERSIONMESSAGE -ne $null) {

    Write-Host "Empty build comment, set it to BUILD_SOURCEVERSIONMESSAGE";


    $buildComment=$Env:BUILD_SOURCEVERSIONMESSAGE

    if ($Env:BUILD_REASON -eq "IndividualCI" -or $Env:BUILD_REASON -eq "BatchedCI") {
        $buildComment = "[CI build] $($Env:BUILD_SOURCEVERSIONMESSAGE)";
    }

    if ($Env:BUILD_REASON -eq "PullRequest") {
        $buildComment = "[PR build] $($Env:BUILD_SOURCEVERSIONMESSAGE)";
    } 

    Write-Host "##vso[task.setvariable variable=build.Comment;]$buildComment";

}


$srcPath=$srcPath.replace("/","\")

Write-Host "##vso[task.setvariable variable=build.SourcePath;]$srcPath";

Write-Host "Get version number"

$pathElements = $srcPath.split("\");


$verRootPath = $pathElements[0];
$sourcesPath= "$($pathElements[1])";


Write-Host "Path elements:"
$pathElements

if ($pathElements.Length -gt 2) {
    
   $sourcesPath = "$($pathElements[1])\$($pathElements[2])";
}

if (($Env:BUILD_SYNCBUILD -ne "true") -or ($Env:BUILD_SYNCBUILDVERSION -eq $null) -or ($Env:BUILD_QUEUEDBYID -ne $buildServiceId)) {

    $sqlQuery = "EXEC tfsBuild_GetVersionNumber '$verRootPath', '$sourcesPath', '$srcPath', '$Env:BUILD_REPOSITORY_ID', '$Env:BUILD_REPOSITORY_NAME'"

    Write-Host "Get version number from database: $sqlQuery";

    $version = Invoke-Sqlcmd -query $sqlQuery -ServerInstance $dbServer -username $dbUserName -password $dbPassword -Database $dbDatabase

    Write-Host "Received version: $($version.majorVersion)";
    Write-Host "Received build: $($version.build)";

    $verMajorPart=$version.majorVersion;    
    $verBuildPart=$version.build;
    $pathType=$version.pathType;

    if ($verMajorPart -eq "error") {

       Write-Host "##vso[task.logissue type=error]Unable to get version number: $verBuildPart";
        Exit 1;
    }
        

    if ($pathType -eq "release") {
        $verBuildPart = $verBuildPart.ToString().PadLeft(4,"0");
    }
    else 
    {
        $verBuildPart = $verBuildPart.ToString().PadLeft(3,"0");
    }


    $esaVersion="$verMajorPart.$verBuildPart";
}
else {
    Write-Host "Syncbuild, set esa version to $Env:BUILD_SYNCBUILDVERSION";


    $esaVersion=$Env:BUILD_SYNCBUILDVERSION

}

Write-Host "##vso[task.setvariable variable=build.esaVersionMain;]$esaVersion"
$esaVersionMain=$esaVersion;

if ($Env:BUILD_PLATFORM -eq "x86")  {
    $esaVersion=$esaVersion + ".32";
}

if ($Env:BUILD_PLATFORM -eq "x64") {
    $esaVersion=$esaVersion + ".64";
}



Write-Host "Esa version: $esaVersion"

$buildName="$($esaVersion)_$($pathElements[-1])_$($Env:BUILD_PLATFORM)"


if ($Env:BUILD_CONFIGURATION -ne "release") {
    $buildName="$($buildName)_$($Env:BUILD_CONFIGURATION)";
}

if ($Env:BUILD_EP_PRODUCT -ne "true") {
    $buildName="$($buildName)_NEP";
 }


 

$buildDisplayName=$buildName;


if ($isTriggerOnlyBuild -eq $true) {

    $buildDisplayName="$($esaVersionMain)_$($pathElements[-1])_x86+x64"
}


if ($Env:BUILD_ALLLANGS -eq "true") {
    $buildDisplayName = "$($buildDisplayName)_langs";
}

Write-Host "##vso[build.updatebuildnumber]$buildDisplayName"

Write-Host "##vso[task.setvariable variable=build.senbuildnumber;]$buildName"
Write-Host "##vso[task.setvariable variable=build.esaVersion;]$esaVersion"




Write-Host "##vso[build.addbuildtag]$($Env:BUILD_CONFIGURATION)"
Write-Host "##vso[build.addbuildtag]$($Env:BUILD_PLATFORM)"

if ($verRootPath -ne "pull") {
    $srcTag=$srcPath.replace("\","/");
    Write-Host "##vso[build.addbuildtag]$srcTag"
}


Write-Host "All env. variables:"
Get-ChildItem Env:

 

if ($isTriggerOnlyBuild -eq $true) {
    Exit 0;
}

Get-Location

$ftpPath="$OutputFtpPath\$srcPath"


if ((Test-Path "filesystem::$($Env:OUTPUTROOT)\$ftpPath") -eq $false ) {

	New-Item -ItemType Directory -Force -Path "filesystem::$($Env:OUTPUTROOT)\$ftpPath"


}


$filePath=($ftpPath -replace "(\\|/)(.)", '$1[$2]') 
	

$filePathWithRoot = "filesystem::$($Env:OUTPUTROOT)\$filePath"
Write-Host "FilePath with root: $filePathWithRoot"

$realName=Get-Item  $filePathWithRoot | Select FullName

$realFtpPath = $realName.FullName.Replace($Env:OUTPUTROOT,'').TrimStart('\')

Write-Host "Original FTP path: $ftpPath"
Write-Host "Real FTP path: $realFtpPath"

$realSrcPath=$realFtpPath.Replace($OutputFtpPath,'').TrimStart('\')

Write-Host "##vso[task.setvariable variable=build.outputftppath;]$realFtpPath";
Write-Host "##vso[task.setvariable variable=build.utftppath;]$OutputFtpUTPath\$realSrcPath\$esaVersion";
Write-Host "##vso[task.setvariable variable=build.utftppathroot;]$OutputFtpUTPath\$realSrcPath";


subst r: /d 2>$null
subst r: $Env:BUILD_SOURCESDIRECTORY


#Update RC files

$appMainVersion = $esaVersionMain.Substring(0,4)

if ($Env:BUILD_PLATFORM -eq "x64") {
    $appNameSEN = "SCIA Engineer $appMainVersion"
    $appNameESA = "SCIA Engineer $appMainVersion Legacy"
 }
else {
   $appNameSEN = "SCIA Engineer $appMainVersion 32bit"
   $appNameESA = "SCIA Engineer $appMainVersion 32bit"
}

writeVersionInfo "$BuildRoot\A\Src\Applications\Prima\PrimaIco.rc" "$appNameESA" "$esaVersionMain"
writeVersionInfo "$BuildRoot\A\Src\Applications\SciaEngineer\SciaEngineerIco.rc" "$appNameSEN" "$esaVersionMain"


#Update sdf version
& $VisBuildPath /b $PSScriptRoot\prebuild\UpdateSdfVersion.bld ESA_VERSION=$esaVersion

#Update OpenApi version
$AssemblyInfoFile="$BuildRoot\A\Src\OpenAPI\OpenAPI\Properties\AssemblyInfo.cs";

if (Test-Path $AssemblyInfoFile) {
	Write-Host "Set version number for OpenAPI";
	(Get-Content $AssemblyInfoFile) | ForEach-Object { $_ -replace "^\[assembly: AssemblyVersion.*", "[assembly: AssemblyVersion(`"$esaVersion`")]" } | ForEach-Object { $_ -replace "\[assembly: AssemblyFileVersion.*", "[assembly: AssemblyFileVersion(`"$esaVersion`")]" } | Set-Content $AssemblyInfoFile
}


$IsEP_PRODUCT = "$BuildRoot\BuildEnv\IsEP_PRODUCT";

if (Test-Path $IsEP_PRODUCT) {
    Remove-Item $IsEP_PRODUCT;
}


if ($Env:BUILD_EP_PRODUCT -eq "true") {
    Write-Host "Enable EP_PRODUCT"
    New-Item $IsEP_PRODUCT -ItemType file -Force
    Write-Host "##vso[build.addbuildtag]EP_PRODUCT"
}


New-Item $BuildRoot\BuildEnv\UseOfSENPostBuildReflection  -ItemType file -Force


if (Test-Path r:\A\Src\ADMIN\_Build\PostBuildReflection.props) {
    Remove-Item r:\A\Src\ADMIN\_Build\PostBuildReflection.props;
}


if ($Env:BUILD_NATIVECODEANALYSIS -eq "true") {
	Write-Host "Enable Native code analysis"
	& $BuildRoot\BuildEnv\NativeCodeAnalysis_Enable.bat

}

Write-Host "Check if XML Config validation can be run"

$runXmlConfigValidation = (Test-Path -Path $xmlConfigValidationPath -PathType Leaf)
Write-Host "Run XML config validation: $runXmlConfigValidation"
Write-Host "##vso[task.setvariable variable=build.RunXMLConfigValidation;]$runXmlConfigValidation";


Write-Host "Check if relative path include test script can be run"
$runRPItestScript = (Test-Path -Path $RelativePathIncludeScriptPath -PathType Leaf)

Write-Host "Run relative path include test: $runRPItestScript"
Write-Host "##vso[task.setvariable variable=build.TestRelativeIncludes;]$runRPItestScript";


Write-Host "Check if TCo tests can be run"

$runTco = ((Test-Path -PathType Container -path r:\TestCompleteTestProject) -and (Test-Path "c:\Program Files (x86)\SmartBear\TestExecute 12\x64\Bin\TestExecute.exe")) -and ($Env:BUILD_EP_PRODUCT -eq "true") -and ($Env:BUILD_PLATFORM -eq "x86") -and ($Env:BUILD_CONFIGURATION -eq "release") 

Write-Host "Run TestComplete tests: $runTco";
Write-Host "##vso[task.setvariable variable=build.RunTestComplete;]$runTco";

Write-Host "Check if Poirot tests can be run"

$runPoirots = (Test-Path -PathType Container -path r:\A\UnitTests\Poirots) -and ($Env:BUILD_EP_PRODUCT -eq "true") -and ($Env:BUILD_CONFIGURATION -eq "release") 

Write-Host "Run Poirot tests: $runPoirots";
Write-Host "##vso[task.setvariable variable=build.RunPoirots;]$runPoirots";


Write-Host "Check if TSM on sources repo should be used"

$useGitTsm = (Test-Path -PathType Container -path $Env:BUILD_SOURCESDIRECTORY\Localization)

Write-Host "Use TSM on git: $useGitTsm"
Write-Host "##vso[task.setvariable variable=build.UseGitTSM;]$useGitTsm";


Write-Host "Check if UTF16 TSM should be used"
$useUtf16Tsm = $true
Write-Host "Use UTF16 TSM: $useUtf16Tsm"
Write-Host "##vso[task.setvariable variable=build.UseUtf16Tsm;]$useUtf16Tsm";


Write-Host "Check if Python script RC translation should be used"
$useScriptRcTranslation = (Test-Path -PathType Leaf -path $Env:BUILD_SOURCESDIRECTORY\Localization\RcFilesConvert.py)
Write-Host "Use Python script for RC translation: $useScriptRcTranslation"
Write-Host "##vso[task.setvariable variable=build.UseScriptRcTranslation;]$useScriptRcTranslation";


Write-Host "Check if Python script for XML translation should be used"
$useScriptXmlTranslation = (Test-Path -PathType Leaf -path $Env:BUILD_SOURCESDIRECTORY\Localization\LangFilesConvert.py)
Write-Host "Use Python script for XML translation: $useScriptXmlTranslation"
Write-Host "##vso[task.setvariable variable=build.UseScriptXmlTranslation;]$useScriptXmlTranslation";


Write-Host "Check if Azure TSM shoud be used"
$useAzureTsm = (Test-Path -PathType Leaf -path $Env:BUILD_SOURCESDIRECTORY\Localization\AzureSQL.py)
Write-Host "Use Azure TSM for translation: $useAzureTsm"
Write-Host "##vso[task.setvariable variable=build.useAzureTsm;]$useAzureTsm";


$snykTargetReference=$esaVersion
$snykTargetReferenceSast=$esaVersion.Replace('.','_')

Write-Host "Check if Snyk scans should be run"
$runSnykScans = (($Env:BUILD_ALLLANGS.ToLower() -eq "true") -and ($srcPath.StartsWith("release\")) -and ($Env:BUILD_SKIPPOIROTS -ne "true"))

if (($Env:BUILD_ALLLANGS.ToLower() -eq "true") -and ($srcPath -eq ("develop")) -and ($Env:BUILD_SKIPPOIROTS -eq "true")) {
	
	$runSnykScans=$true
	$snykTargetReference="develop"
	$snykTargetReferenceSast="develop"
	
}


Write-Host "Run Snyk scans: $runSnykScans"
Write-Host "SnykTargetReference: $snykTargetReference"
Write-Host "##vso[task.setvariable variable=build.runSnykScans;]$runSnykScans";


Write-Host "##vso[task.setvariable variable=build.snykTargetReference;]$snykTargetReference"
Write-Host "##vso[task.setvariable variable=build.snykTargetReferenceSast;]$snykTargetReferenceSast"

if ($useScriptRcTranslation -eq $false) {

    Write-Host "##vso[task.logissue type=error]This branch doesn't support new scripts for language translation. It still uses RCmaker, which is not supported anymore";
    Exit 1

}

#Write-Host "Check if OpenAPI integration tests can be run"

#$runOpenApiTests = (Test-Path -PathType Leaf -path r:\A\Src\Plugins\OpenAPI_InT\cid.run.openapi.InT.flag ) -and ($Env:BUILD_EP_PRODUCT -eq "true") -and ($Env:BUILD_PLATFORM -eq "x86") -and ($Env:BUILD_CONFIGURATION -eq "release") 

#Write-Host "Run OpenApi tests tests: $runOpenApiTests";
#Write-Host "##vso[task.setvariable variable=build.RunOpenApiTests;]$runOpenApiTests";

#if (Test-Path $oapiTestDrive) {
#	Write-Host "Drive $oapiTestDrive for $oapiTestNetPath already exists"
#}
#else
#{
#	Write-Host "Map drive $oapiTestDrive for $oapiTestNetPath"
#	net use $oapiTestDrive $oapiTestNetPath
#}



Write-Host "Prepare BuildResults folder"
New-Item -ItemType Directory -Force -Path $BuildResulsFolder
Remove-Item "$BuildResulsFolder\*" -Recurse


Write-Host "Delete ESA folder and registry"


Write-Host "Registry version: $appMainVersion";

$esaDir= $Env:USERPROFILE + "\ESA" + $appMainVersion;

Write-Host "ESA folder: $esaDir";
if (Test-Path -Path $esaDir -PathType Container) {
    Write-Host "Delete ESA folder $esaDir";
    Remove-Item -Path $esaDir -Recurse -Force;
}

$esaRegPath="HKCU:\Software\SCIA\Esa\$appMainVersion"

Write-Host "Registry path: $esaRegPath";
if (Test-Path -Path $esaRegPath -PathType Container) {
    Write-Host "Delete registry key $esaRegPath";
    Remove-Item -Path $esaRegPath -Recurse -Force;
}

#if (Test-Path $oapiTestLockName) {
#	 Write-Host "Remove lock $oapiTestLockName"
#    Remove-Item $oapiTestLockName;
#}


Write-Host "Done."
