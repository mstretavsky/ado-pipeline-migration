
$url="$($Env:SYSTEM_COLLECTIONURI)$($Env:SYSTEM_TEAMPROJECT)/_apis/build/builds/$($Env:BUILD_BUILDID)/timeline?api-version=7.0"

$result=Invoke-RestMethod -Uri $url -Headers @{authorization = "Bearer $($Env:SYSTEM_ACCESSTOKEN)"}-ContentType "application/json" -Method get

$taskResult=$result.records | where {$_.name -eq "VsTest - Poirots"} | select result  


Write-Host "VsTest - Poirots step result: $($taskResult.result)"

if ($taskResult.result -eq "succeededWithIssues") {

Write-Host "##vso[task.logissue type=error]Inspect failing test results in ResultsForStage1 folder of build pipeline files. These can be downloaded at $($Env:SYSTEM_COLLECTIONURI)$($Env:SYSTEM_TEAMPROJECT)/_build/results?buildId=$($Env:BUILD_BUILDID)&view=scia.scia-cid-devops-devstaging.build-utils-tab . Update TST files, placed in A/UnitTests/Poirots, to fix these fails."

}