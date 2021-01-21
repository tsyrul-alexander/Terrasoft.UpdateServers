[string]$WCPath = GetConfigValue -Key "InstallPackageServerWCPath";
[string]$SitePath = GetConfigValue -Key "InstallPackageServerConfPath";
[string]$InstallPackageBuildServerPackageDirectory = GetConfigValue -Key "InstallPackageBuildServerPackageDirectory";
[string]$InstallPackageBuildServerPackageTempDirectory = GetConfigValue -Key "InstallPackageBuildServerPackageTempDirectory";
[string]$InstallPackageServerWCLogPath = GetConfigValue -Key "InstallPackageServerWCLogPath";
function InstallWCPackage {
    param (
        [object] $Session,
        [string] $PackageDirectory
    )
    Invoke-Command @{
        Session = $Session
        ScriptBlock = { 
            Param ($wcPath,$sitePath, $packageDirectory, $packageTempDirectory, $logPath)
            & "$wcPath -workspaceName=Default -operation=InstallFromRepository -updateSystemDBStructure=true -installPackageSqlScript=true -installPackageData=true -sourcePath=$packageDirectory -destinationPath=$packageTempDirectory -confRuntimeParentDirectory=$sitePath -clearWorkspace=false -continueIfError=true -logPath=$logPath"
        }
        ArgumentList = $WCPath, $SitePath, $InstallPackageBuildServerPackageDirectory, $InstallPackageBuildServerPackageTempDirectory, $InstallPackageServerWCLogPath;
    }
}