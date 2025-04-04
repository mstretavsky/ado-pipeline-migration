#Script variables, should be called at the beginning of each step script

. "$PSScriptRoot\functions.ps1"


$VisBuildPath="c:\Program Files (x86)\VisBuildPro8\VisBuildCmd.exe"

$BuildRoot="R:"
$OutputDir="$BuildRoot\a\bin\release\"
$OutputInstallDir="$BuildRoot\a\bin\release\install\"
$BuildResulsFolder="$BuildRoot\BuildResults"


$RelativePathIncludeScriptPath="$BuildRoot\A\Util\Scripts\test_relative_includes.ps1"

$xmlConfigValidationPath="$($Env:BUILD_SOURCESDIRECTORY)\A\Util\XmlConfig\XmlConfig.exe"

$AP_reg_file="$OutputInstallDir\A_P.reg.builder.bat"
$Nexis_reg_file="$OutputInstallDir\Nex4_all.reg.builder.bat"


$OutputFtpPath="VersionsDeve\TFS{suffix}"
$OutputFtpUTPath="VersionsDeve\TFS{suffix}UnitTestResults"

$ScriptWorkRoot = (Split-Path $Env:ScriptFolder -Qualifier) + '\tfswork';


#DATABASE CREDENTIALS
$dbServer = "AZURESDEV001";
$dbUserName = "builder";
$dbPassword = "Bldr.147.QpMa*";
$dbDatabase="PortalDeve";

#OPENAPI tests
$oapiTestComputer="192.168.162.39"
$oapiTestDrive="T:"
$oapiTestNetPath="\\$oapiTestComputer\OpenAPITests"
$oapiTestLocksFolder="$oapiTestDrive\locks"
$oapiTestLockName = "$oapiTestLocksFolder\$Env:AGENT_NAME"


$isTriggerOnlyBuild = ($Env:AGENT_NAME -like "*Sync*");


$buildServiceId="8523884f-905c-48c2-b909-983306fd7028"