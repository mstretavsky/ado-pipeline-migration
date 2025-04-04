. "$PSScriptRoot\variables.ps1"


$7zMd5 = & $PSScriptRoot\postbuild\md5.exe -l -n $Env:BUILD_SOURCESDIRECTORY\_packed\$Env:BUILD_FULL7ZFILENAME

Write-Host "7z MD5: $7zMd5";
Write-Host "##vso[task.setvariable variable=build.7zMD5;]$7zMd5";


#nexis UT
if ($Env:BUILD_PLATFORM -eq "x86") {
    Write-Host "Running NEXIS unit tests...";

     Get-Content $PSScriptRoot\postbuild\X_to_A.txt| Foreach-Object{
     if (Test-Path $OutputDir\$_) {
      copy-item -path $OutputDir\$_ -destination "R:\Nexis" -Recurse -Container -Force}
    }

    "Running $OutputInstallDir\UnitTestRunnerMB.exe -id R:\Nexis -o $BuildResulsFolder\UT_Epw_Out.log -l $BuildResulsFolder\UT_Epw.log" | Write-Host
    & $OutputInstallDir\UnitTestRunnerMB.exe -id "R:\Nexis" -o "$BuildResulsFolder\UT_Epw_Out.log" -l "$BuildResulsFolder\UT_Epw.log" | Out-Null
    
}

Write-Host "Copy MSUT files"
copy $BuildRoot\UnitTestsOut\*.* $BuildResulsFolder\ -Force

if (Test-Path -Path $BuildRoot\UnitTestsOut\TestResults -PathType Container)  {
	copy $BuildRoot\UnitTestsOut\TestResults\*.* $BuildResulsFolder\ -Force
}

$LogPath="$BuildRoot\A\Out\ConfigBuild\ESA_Build__All_BuildLog.txt"
Compress-Archive -LiteralPath $LogPath -CompressionLevel Optimal -DestinationPath $BuildResulsFolder\EsaBuildLog.zip



Write-Host "Write build history"
$BHoutDir="$Env:OUTPUTROOT\$Env:BUILD_OUTPUTFTPPATH\FullVer"


if ((Test-Path $BHoutDir) -eq $false) {
    New-Item $BHoutDir -ItemType Directory
}

if ($Env:BUILD_USESCRIPTRCTRANSLATION -eq $true)
{
    $translationReportPath = "\\prgnas\VersionsDeve\esalang\TranslationReports\$($Env:BUILD_SOURCEPATH)\$($Env:BUILD_ESAVERSION)"

    mkdir $translationReportPath -Force
    Copy-Item $BuildRoot\TranslationReport\*.zip $translationReportPath
}

$Env:BUILD_ESAVERSION| Out-File $BHoutDir\builds_history.txt -Encoding ascii -Append

$Env:BUILD_ESAVERSION| Out-File $BHoutDir\builds_history_$($Env:BUILD_PLATFORM).txt -Encoding ascii -Append


if ((Test-Path -Path $BuildRoot\A\Src\OpenAPI\OpenAPI -PathType Container) -and $Env:BUILD_ALLLANGS -eq "true") {


    $Doxygen7zPath="$BuildResulsFolder\SCIA.OpenAPI.doc.doxygen.$($Env:BUILD_ESAVERSIONMAIN).7z"

    Copy-Item  $PSScriptRoot\postbuild\doxygen\openapi.doxygen -Destination $ScriptWorkRoot -Force

    "PROJECT_NUMBER         = $($Env:BUILD_ESAVERSIONMAIN) " | Out-File $ScriptWorkRoot\openapi.doxygen -Encoding utf8 -Append

    $DoxygenGenerPath="$ScriptWorkRoot\doxygen.gener"

    Write-Host "Generating API documentation..."

    if (Test-Path -Path $DoxygenGenerPath -PathType Container) {
        Remove-Item $DoxygenGenerPath -Recurse
    }

    & $PSScriptRoot\postbuild\doxygen\bin\doxygen.exe $ScriptWorkRoot\openapi.doxygen 1>$BuildResulsFolder\doxygen.log 2>&1


    if (Test-Path -Path $Doxygen7zPath -PathType Leaf) {
        Remove-Item $Doxygen7zPath
    }

    & $PSScriptRoot\pack\7za.exe a -r $Doxygen7zPath $DoxygenGenerPath\*


}


Write-Host "Done."
Exit 0