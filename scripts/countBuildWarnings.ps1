. "$PSScriptRoot\variables.ps1"

#count warnings
Write-Host "Count warnings"
$CountWarningsExePath="$BuildRoot\a\util\CountWarnings.exe"
$CountWarningsScriptPath="$BuildRoot\A\Util\Scripts\projects_warning_count.ps1"

$CountWarningsOutput="$BuildResulsFolder\WarningsCount.csv"
$CountWarningsLog="$BuildResulsFolder\WarningsCountLog.txt"
$LogPath="$BuildRoot\A\Out\ConfigBuild\ESA_Build__All_BuildLog.txt"


if (Test-Path $CountWarningsScriptPath) {

	Write-Host "Run $CountWarningsScriptPath $LogPath $CountWarningsOutput"
	"Run $CountWarningsScriptPath $LogPath $CountWarningsOutput" | Set-Content $CountWarningsLog
	. $CountWarningsScriptPath $LogPath $CountWarningsOutput


}

elseif (Test-Path $CountWarningsExePath) {

    "Run $CountWarningsExePath -file $LogPath -output $CountWarningsOutput" | Set-Content $CountWarningsLog
    & $CountWarningsExePath -file $LogPath -output $CountWarningsOutput | Add-Content $CountWarningsLog


	If (Test-Path $CountWarningsLog) {
		Get-Content $CountWarningsLog | Write-Host
	}

}
else {
	Write-Host "Count of warnings not available. $CountWarningsScriptPath or $CountWarningsPath not found"
    "Count of warnings not available. $CountWarningsScriptPath or $CountWarningsPath not found" | Set-Content $CountWarningsLog
}


Exit 0