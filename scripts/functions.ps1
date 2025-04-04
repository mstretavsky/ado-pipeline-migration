#General functions

function PrepareLangsWork ($scriptFiles,$rootPath) {

    Write-Host "Call PrepareLangsWork $rootPath"
    foreach ($file in $scriptFiles)
    {
        (Get-Content $file.PSPath) |
        Foreach-Object { $_ -replace "%%TRANS_ROOT%%", $rootPath } |
        Set-Content $file.PSPath
    }


}




function writeVersionInfo ($fileName, $appName, $appVersion)
{
	if (Test-Path $fileName) {
		(Get-Content $fileName) `
		-replace 'VALUE "FileDescription".*$', "VALUE ""FileDescription"",""$appName"""`
		-replace 'VALUE "ProductName".*$', "VALUE ""ProductName"",""$appName"""`
		-replace 'VALUE "FileVersion".*$', "VALUE ""FileVersion"",""$appVersion"""`
		-replace 'VALUE "ProductVersion".*$', "VALUE ""ProductVersion"",""$appVersion"""`
		 | Out-File $fileName  -Encoding ascii
	
	}
	
}