. "$PSScriptRoot\variables.ps1"


if (Test-Path -Path $RelativePathIncludeScriptPath -PathType Leaf) {
	
	Write-Host "Running relative path include test script: $RelativePathIncludeScriptPath"
	

$result = & $RelativePathIncludeScriptPath "$BuildRoot\A\Src"

if ($result) {
	Write-Host "`nNo errors have been found in relative path include test script"
	Exit 0
}
else {
	Write-Host "##vso[task.logissue type=error]Errors have been found during relative path include testing! See the log for details."
	Exit 1
}


}