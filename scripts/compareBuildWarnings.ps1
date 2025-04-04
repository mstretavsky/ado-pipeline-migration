. "$PSScriptRoot\variables.ps1"


$compareBranch=$Env:BUILD_SOURCEBRANCH.replace("refs/heads/","");
$baseBranch="develop"


Write-Host "Base branch: $baseBranch"
Write-Host "Compare branch: $compareBranch"

pushd $Env:BUILD_SOURCESDIRECTORY;
$sha1 = & git merge-base "origin/$baseBranch" "origin/$compareBranch"

Write-Host "SHA of common commit: $sha1"

$is64bitBuild = 0

if ($Env:BUILD_PLATFORM -eq "x64") {
	$is64bitBuild=1
}

$baseBuild = Invoke-Sqlcmd -query "EXEC tfsBuild_GetBuildForCommit '$sha1', '$baseBranch', '$is64bitBuild'" -ServerInstance $dbServer -username $dbUserName -password $dbPassword -Database $dbDatabase

$baseBuildVersion = $baseBuild.versionNumber
$baseBuildUtPath = $baseBuild.utPathRoot

if ($baseBuildVersion -eq "0") {
	Write-Host $baseBuildUtPath
	Exit 0
}

Write-Host "Base build version: $baseBuildVersion"
Write-Host "Base build UT path: $baseBuildUtPath"

$baseBuildWarningsFile = "FileSystem::$Env:OutputRoot\$baseBuildUtPath\$baseBuildVersion\WarningsCount.csv"

Write-Host "WarningsCountFile for base build: $baseBuildWarningsFile"
if (-not (Test-Path $baseBuildWarningsFile)) {
	Write-Host "File does not exist!"
	Exit 0
}
	
$compareBuildWarningsFile="$BuildResulsFolder\WarningsCount.csv"
	
Write-Host "WarningsCountFile for compare build: $compareBuildWarningsFile"
if (-not (Test-Path $compareBuildWarningsFile)) {
	Write-Host "File does not exist!"
	Exit 0
}
	
		
Write-Host "Running warning compare script..."
Write-Host "****************************************************************************"

. $PSScriptRoot\postbuild\warning-compare.ps1 $baseBuildWarningsFile $compareBuildWarningsFile

$warningsCount=$LASTEXITCODE

#Write-Host "Warnings count: $warningsCount"
if ($warningsCount -gt 0) {
	
	Write-Host "##[command]Inspect new warnings in details by downloading build pipeline files at $($Env:SYSTEM_COLLECTIONURI)$($Env:SYSTEM_TEAMPROJECT)/_build/results?buildId=$($Env:BUILD_BUILDID)&view=scia.scia-cid-devops-devstaging.build-utils-tab"
}


Exit 0