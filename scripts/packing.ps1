. "$PSScriptRoot\variables.ps1"


$fileName7z= $Env:BUILD_SENBUILDNUMBER + ".7z"
$fullFileName7z="Full_" + $fileName7z;

$actFileName="Act_Full_" +$Env:BUILD_SOURCEBRANCHNAME;



if ($Env:BUILD_PLATFORM -eq "x64") {
    $actFileName = $actFileName + "_x64";

}


$actFileName = $actFileName + ".7z";
Write-Host "##vso[task.setvariable variable=build.full7zFileName;]$fullFileName7z";


Write-Host "Packed filename: $fullFileName7z";

if ((Test-Path $Env:BUILD_SOURCESDIRECTORY\_packed\) -eq $false) {
    mkdir -Path $Env:BUILD_SOURCESDIRECTORY\_packed\
}

Remove-Item $Env:BUILD_SOURCESDIRECTORY\_packed\*.* -Force


Set-Location $Env:BUILD_SOURCESDIRECTORY\a\bin\release\install\


& $PSScriptRoot\pack\7za.exe a -r $Env:BUILD_SOURCESDIRECTORY\_packed\$fullFileName7z *

if ($Env:BUILD_SOURCEBRANCHNAME -ne "merge") {
    Copy-Item $Env:BUILD_SOURCESDIRECTORY\_packed\$fullFileName7z -Destination $Env:BUILD_SOURCESDIRECTORY\_packed\$actFileName

}


Write-Host "Done."
Exit 0