. .\Config.ps1;
. .\Remote-Helper.ps1;
. .\Logger.ps1;
. .\Remote-WSCommand.ps1;
[string]$LoaderDirectory = GetConfigValue -Key "InstallPackageServerLoaderDirectory";
[string]$WebAppDirectory = Join-Path -Path $LoaderDirectory -ChildPath "Terrasoft.WebApp";
[string]$ConfigurationBinDirectory = Join-Path -Path $ConfigurationDirectory -ChildPath "bin";
[string]$WebAppRuntimeDataDirectory = Join-Path -Path $WebAppDirectory -ChildPath "conf\runtime-data";
[string]$WebAppConfigurationBuildDirectory = Join-Path -Path $WebAppDirectory -ChildPath "conf\bin";
[string]$RemoteUserLogin = GetConfigValue -Key "RemoteUserLogin";
[string]$RemoteUserPassword = GetConfigValue -Key "RemoteUserPassword";
[string]$LocalWebAppBinDirectory = GetConfigValue -Key "WebAppBinDirectory";
[string]$LocalWebAppRuntimeDataDirectory = GetConfigValue -Key "WebAppRuntimeDataDirectory";
[string]$LocalConfigurationBinDirectory = GetConfigValue -Key "ConfigurationBinDirectory";
[string]$WebAppRuntimeDataDirectory = GetConfigValue -Key "WebAppRuntimeDataDirectory";
[string[]]$Servers = (GetConfigValue -Key "InstallPackageServerIps").Split(",");

function SendConfigurationBuild {
    param ([object]$Sessions)
    SendRemoteFile -Session $Sessions -Source ($LocalWebAppBinDirectory + "\*") -Destination ($WebAppConfigurationBuildDirectory + "\");
    SendRemoteFile -Session $Sessions -Source ($LocalConfigurationBinDirectory + "\*") -Destination ($ConfigurationBinDirectory + "\");
    SendRemoteFile -Session $Sessions -Source ($LocalWebAppRuntimeDataDirectory + "\*") -Destination ($WebAppRuntimeDataDirectory + "\");
}
function InstallUpdateToOtherSites {
    param ()
    $sessions = CreateSession -ServersIp $Servers -Login $RemoteUserLogin -Pass $RemoteUserPassword;
    foreach($serverSession in $sessions) {
        StopServer -Sessions $serverSession;
        SendConfigurationBuild -Sessions $serverSession;
        StartServer -Sessions $serverSession;
    }
    WCBuildConfiguration -Session $sessions;
    $sessions | Remove-PSSession;
}