. .\Config.ps1;
. .\Remote-Helper.ps1;
. .\Logger.ps1;
. .\Remote-WSCommand.ps1;
[string]$PackageDirectory = GetConfigValue -Key "PackageDirectory";
[string]$InstallPackageBuildServerIp = GetConfigValue -Key "InstallPackageBuildServerIp";
[string]$RemoteUserLogin = GetConfigValue -Key "RemoteUserLogin";
[string]$RemoteUserPassword = GetConfigValue -Key "RemoteUserPassword";
function SendPackage {
    param ([object] $Session)
    Log -Message "Send package from $PackagePath to $ComputerPackageFolder"
    SendRemoteFile -Session $sessions -Source $PackagePath -Destination $ComputerPackageFolder;
}

function InstallPackage {
    param ([string]$PackagePath)
    Log -Message "Start install package";
    $sessions = CreateSession -ServersIp $InstallPackageBuildServerIp -Login $RemoteUserLogin -Pass $RemoteUserPassword;
    SendPackage -Session $sessions;
    InstallWCPackage -Session $sessions -PackageDirectory $PackageDirectory;
    $sessions | Remove-PSSession;
    Log -Message "End install package";
}

Main;