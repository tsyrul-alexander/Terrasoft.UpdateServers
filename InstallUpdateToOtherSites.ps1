. .\Config.ps1;
. .\Remote-Helper.ps1;
. .\Logger.ps1;
. .\Remote-WSCommand.ps1;
[string]$LoaderDirectory = GetConfigValue -Key "InstallPackageServerLoaderDirectory";
[string]$WebAppDirectory = Join-Path -Path $LoaderDirectory -ChildPath "Terrasoft.WebApp";
[string]$ConfigurationBinDirectory = Join-Path -Path $ConfigurationDirectory -ChildPath "bin";
[string]$WebAppConfigurationDirectory = Join-Path -Path $WebAppDirectory -ChildPath "conf";
[string]$WebAppRuntimeDataDirectory = Join-Path -Path $WebAppConfigurationDirectory -ChildPath "runtime-data";
[string]$WebAppConfigurationBuildDirectory = Join-Path -Path $WebAppConfigurationDirectory -ChildPath "bin";
[string]$RemoteUserLogin = GetConfigValue -Key "RemoteUserLogin";
[string]$RemoteUserPassword = GetConfigValue -Key "RemoteUserPassword";
[string]$LocalWebAppBinDirectory = GetConfigValue -Key "WebAppBinDirectory";
[string]$LocalWebAppRuntimeDataDirectory = GetConfigValue -Key "WebAppRuntimeDataDirectory";
[string]$LocalConfigurationBinDirectory = GetConfigValue -Key "ConfigurationBinDirectory";
[string[]]$Servers = (GetConfigValue -Key "InstallPackageServerIps").Split(",");

function SendConfigurationBuild {
    param ([object]$Session)
    Log -Message "Send configuration build to other sites";
    SendRemoteFile -Session $Session -Source ($LocalWebAppBinDirectory + "\bin\*") -Destination ($WebAppConfigurationBuildDirectory + "\");
    SendRemoteFile -Session $Session -Source ($LocalWebAppBinDirectory + "\_MetaInfo.json") -Destination ($WebAppConfigurationDirectory + "\");
    SendRemoteFile -Session $Session -Source ($LocalConfigurationBinDirectory + "\*") -Destination ($ConfigurationBinDirectory + "\");
    SendRemoteFile -Session $Session -Source ($LocalWebAppRuntimeDataDirectory + "\*") -Destination ($WebAppRuntimeDataDirectory + "\");
}
function RemoveConfigurationBuild {
    param ([object] $Session)
    Log -Message "Removed old configuration builds";
    Invoke-Command -Session $Session -ScriptBlock {
        Param ($webAppBinDirectory)
        Get-ChildItem -Path $webAppBinDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
    } -ArgumentList $WebAppConfigurationBuildDirectory;
}
function InstallUpdateToOtherSites {
    param ()
    Log -Message "Start install update to other sites";
    $sessions = CreateSession -ServersIp $Servers -Login $RemoteUserLogin -Pass $RemoteUserPassword;
    foreach($serverSession in $sessions) {
        Log -Message "Stop web server";
        StopServer -Session $serverSession;
        RemoveConfigurationBuild -Session $serverSession;
        SendConfigurationBuild -Session $serverSession;
        Log -Message "Start web server";
        StartServer -Session $serverSession;
    }
    WCBuildConfiguration -Session $sessions;
    Log -Message "End install update to other sites";
    $sessions | Remove-PSSession;
}