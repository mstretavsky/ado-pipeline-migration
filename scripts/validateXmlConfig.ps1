. "$PSScriptRoot\variables.ps1"


if (Test-Path -Path $xmlConfigValidationPath -PathType Leaf) {
		
	$srcDir=$Env:BUILD_SOURCESDIRECTORY
	
	Write-Host "Running XML Config validation tool: $xmlConfigValidationPath"
	
	Write-Host "$xmlConfigValidationPath -c $srcDir\A\Util\XmlConfig\build_validation\xcfg*.xml -p $srcDir -z"

	& $xmlConfigValidationPath -c $srcDir\A\Util\XmlConfig\build_validation\xcfg*.xml -p $srcDir -z


	$ret= $LASTEXITCODE
	Write-Host "XML Config validation result: $ret"
	
	#Success = 0,  InvalidCommandLineArguments,  ErrorInConfigFile, WarningDuringEvaluation, ErrorDuringEvaluation
	if (($ret -eq 0) -or ($ret -eq 3)) {
		Exit 0
	}
	else {
		Exit 1
	}

}
else {
	Write-Host "XML Config validation tool not found"
	
	Exit 0
}