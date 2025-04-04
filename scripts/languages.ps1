. "$PSScriptRoot\variables.ps1"

chcp

if ([System.Environment]::OSVersion.Version.Major -eq 6) {
	chcp 852
	chcp
}

$DeveName=$ENV:BUILD_OUTPUTFTPPATH.Split("\")[-1]

if (Test-Path $BuildRoot\A\_ConfigBuilder\_BuildConfigEnvVars2022.bat) {

    Write-Host "Build in VS2022"
    $Env:BUILDVS22="YES"
}
elseif (Test-Path $BuildRoot\A\_ConfigBuilder\_BuildConfigEnvVars2019.bat) {

    Write-Host "Build in VS2019"
    $Env:BUILDVS19="YES"
}
else {
    Write-Host "Build in VS2015"
    $Env:BUILDVS15="YES"
}


Write-Host "****************************************************"
if ($Env:BUILD_USEGITTSM -eq $true) {
	Write-Host "Using translation memory from git sources"
}
else {
	Write-Host "Using translation memory from SVN repository"
}
Write-Host "****************************************************"

Write-Host "Prepare workfolder"


$langsSrcRoot = "$PSSCriptRoot\languages\RCTrans\"
$langsWorkRoot = "$ScriptWorkRoot\RCtrans";

if ($Env:BUILD_USEUTF16TSM -eq $true)
{
	$langsSrcRoot = "$PSSCriptRoot\languages\RCTrans_Unicode\"
	$langsWorkRoot = "$ScriptWorkRoot\RCtrans_Unicode";
	
}

Write-Host "LangsSrcRoot: $langsSrcRoot"
Write-Host "LangsWorkRoot: $langsWorkRoot"

New-Item $langsWorkRoot -ItemType Directory -Force

Copy-Item -Path "$($langsSrcRoot)\*" $langsWorkRoot -Recurse -Force

$scriptFiles = Get-ChildItem $langsWorkRoot\Translations\*.txt

PrepareLangsWork $scriptFiles $langsWorkRoot;


Write-Host "Prepare languages"

$langs = @{}
$allLangs="";

Get-Content $PSScriptRoot\postbuild\Langs_list.txt  | Foreach-Object{
 $arr = $_.split(" ");
 
 $langs[$arr[0]]=$_
 $allLangs= $allLangs+$arr[0]+",";
 }


 $allLangs = $allLangs.TrimEnd(",")
 $selectedLangs= "".split(","); #replace with variable

if ($Env:BUILD_ALLLANGS -eq "true") {
    $selectedLangs=$allLangs.Split(",");
}

Write-Host "Languages selected for translation:"
$selectedLangs;



$SelectedLangsFile="$langsWorkRoot\Translations\Langs_selected.txt";

New-Item $SelectedLangsFile -ItemType file -Force

 foreach ($lng in $selectedLangs) {

  $langs[$lng] | Add-Content $SelectedLangsFile
 }



 if ($Env:BUILD_USESCRIPTRCTRANSLATION -eq $true)
 {
    Write-Host "Translate languages with Python script"


    if (Test-Path "$BuildRoot\TranslationReport") {
        Remove-Item "$BuildRoot\TranslationReport" -Recurse
    }

    . $PSScriptRoot\postbuild\translateRCfiles.ps1 $SelectedLangsFile $BuildRoot $Env:BUILD_ALLLANGS "$PSScriptRoot\pack\7za.exe"

 }
else {

Write-Host "Translate languages with RCMaker"
    pushd $langsWorkRoot
    & $VisBuildPath /b $langsWorkRoot\RCTrans.bld DEVE_NAME=$DeveName VERSION_NUMBER=$Env:BUILD_ESAVERSION
    $visBuildExitCode = $LASTEXITCODE
    popd

    if ($visBuildExitCode -gt 0) {
    Write-Host "Visual build ExitCode: $visBuildExitCode"
    Exit $visBuildExitCode                                                      
    }

}


Write-Host "Copy english language DLLs back to release"
Copy-Item -Path $OutputInstallDir\*_09.dll $OutputDir -Recurse -Force | Out-Null
Copy-Item -Path $OutputInstallDir\*_US.dll $OutputDir -Recurse -Force | Out-Null

if ($selectedLangs -ne $null) {
    foreach ($lng in $selectedLangs) {
     $arr= $langs[$lng].Split(" ")
     if (Test-Path "$OutputInstallDir\solv_$($arr[2]).dll") {
        Copy-Item -Path "$OutputInstallDir\solv_$($arr[2]).dll" "$OutputInstallDir\solv64_$($arr[2]).dll" -Force
     }
     if (Test-Path "$OutputInstallDir\esa_$($arr[1]).dll") {
        Copy-Item -Path "$OutputInstallDir\esa_$($arr[1]).dll" "$OutputInstallDir\esaL_$($arr[1]).dll" -Force
     }
    }
}


if ($Env:BUILD_ALLLANGS -eq "true") {
	

    if ($Env:BUILD_USESCRIPTXMLTRANSLATION -eq $true) {
        Write-Host "Use Python script for XML translation"
        . $PSScriptRoot\postbuild\translateXmlLangFiles.ps1 $SelectedLangsFile $BuildRoot "$PSScriptRoot\pack\7za.exe" $Env:BUILD_USEAZURETSM
    }
    elseif (Test-Path "$BuildRoot\A\Util\Scripts\Translation\translate_string_xml.ps1") {
		
		
		if ($Env:BUILD_USEGITTSM -eq $true) {
			$tsmFolder="$($Env:BUILD_SOURCESDIRECTORY)\Localization\esa_vocabs\_TSM"
		}
		else {
			$tsmFolder="$langsWorkRoot\SVN\_TSM"
		}
		
		. $PSScriptRoot\postbuild\translateXmlFiles.ps1 $selectedLangsFile $OutputInstallDir "$tsmFolder" "$BuildRoot\A\Util\Scripts\Translation" $Env:BUILD_USEUTF16TSM $Env:BUILD_USESCRIPTRCTRANSLATION
        
        if ($Env:BUILD_USESCRIPTRCTRANSLATION -eq $true) {
            $projectsRootPath = "\\prgnas\versionsDeve\esalang\TranslationReports\$($Env:BUILD_SOURCEPATH)\$($Env:BUILD_ESAVERSION)"
            $zipFileName="XML"
        }
        else {
            $projectsRootPath = "\\prgnas\versionsDeve\esalang\_TSM_Easy\$($Env:BUILD_SOURCEBRANCHNAME)\$($Env:BUILD_ESAVERSION)"
            $zipFileName="xml_report_$($Env:BUILD_SOURCEBRANCHNAME )_$($Env:BUILD_ESAVERSION)"
        }
		
		. $PSScriptRoot\postbuild\packXmlTranslationProjects.ps1 $selectedLangsFile  $OutputInstallDir $PSScriptRoot\pack\7za.exe $projectsRootPath $zipFileName $Env:BUILD_USESCRIPTRCTRANSLATION
	}
	
	
    Write-Host "Translate C# dlls"


    if ($Env:BUILD_USESCRIPTRCTRANSLATION -eq $true)
    {
        Write-Host "Translate C# languages with Python script"
        . $PSScriptRoot\postbuild\translateResXfiles.ps1 $SelectedLangsFile $BuildRoot "$PSScriptRoot\pack\7za.exe" "$PSScriptRoot\postbuild\translationTools" false $Env:BUILD_USEAZURETSM


        Write-Host "Translate SolverStrings.xml with Python script"
        . $PSScriptRoot\postbuild\translateSolverStrings.ps1 $SelectedLangsFile $BuildRoot "$PSScriptRoot\pack\7za.exe" $Env:BUILD_USEAZURETSM

    }
    else {

        Write-Host "Translate C# languages with RCMaker"

        Write-Host "Prepare C# workfolder"
        $csLangsWorkRoot = "$ScriptWorkRoot\CStrans";
        New-Item $csLangsWorkRoot -ItemType Directory -Force
        Copy-Item -Path $PSSCriptRoot\languages\CStrans\* $csLangsWorkRoot -Recurse -Force

        $scriptFiles = Get-ChildItem $csLangsWorkRoot\Translations\*.txt

        PrepareLangsWork $scriptFiles $csLangsWorkRoot;

        Push-Location $csLangsWorkRoot
        & $csLangsWorkRoot\compileCSLang.cmd  $DeveName $Env:BUILD_ESAVERSION
        $visBuildExitCode = $LASTEXITCODE
        Pop-Location


        if ($visBuildExitCode -gt 0) {
        Write-Host "Visual build ExitCode: $visBuildExitCode"
        Exit $visBuildExitCode                                                      
        }
    }
}
else {
    Write-Host "C# dlls translation not required"
}

Write-Host "Done."
