. .\Config.ps1;
. .\Remote-Helper.ps1;
. .\Logger.ps1;
. .\Remote-WSCommand.ps1;
[string]$PackageDirectory = GetConfigValue -Key "PackageDirectory";
[string]$InstallPackageBuildServerIp = GetConfigValue -Key "InstallPackageBuildServerIp";
[string]$InstallPackageBuildServerPackageDirectory = GetConfigValue -Key "InstallPackageBuildServerPackageDirectory";
[string]$RemoteUserLogin = GetConfigValue -Key "RemoteUserLogin";
[string]$RemoteUserPassword = GetConfigValue -Key "RemoteUserPassword";
[string]$LoaderDirectory = GetConfigValue -Key "InstallPackageServerLoaderDirectory";
[string]$WebAppDirectory = Join-Path -Path $LoaderDirectory -ChildPath "Terrasoft.WebApp";
[string]$ConfigurationDirectory = Join-Path -Path $WebAppDirectory -ChildPath "Terrasoft.Configuration";
[string]$ConfigurationBinDirectory = Join-Path -Path $ConfigurationDirectory -ChildPath "bin";
[string]$WebAppConfigurationDirectory = Join-Path -Path $WebAppDirectory -ChildPath "conf";
[string]$WebAppRuntimeDataDirectory = Join-Path -Path $WebAppConfigurationDirectory -ChildPath "runtime-data";
[string]$WebAppConfigurationBuildDirectory = Join-Path -Path $WebAppConfigurationDirectory -ChildPath "bin";
[string]$LocalConfigurationBinDirectory = GetConfigValue -Key "ConfigurationBinDirectory";
[string]$LocalWebAppRuntimeDataDirectory = GetConfigValue -Key "WebAppRuntimeDataDirectory";
[string]$LocalWebAppBinDirectory = GetConfigValue -Key "WebAppBinDirectory";
function SendPackage {
    param ([object] $Session)
    Log -Message "Send package to install server";
    Invoke-Command -Session $Session -ScriptBlock {
        Param ($packageDirectory)
        Get-ChildItem -Path $packageDirectory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
    } -ArgumentList $InstallPackageBuildServerPackageDirectory;
    SendRemoteFile -Session $sessions -Source ($PackageDirectory + "\*") -Destination ($InstallPackageBuildServerPackageDirectory + "\");
    Invoke-Command -Session $Session -ScriptBlock {
        Param ($packageDirectory)
        $zipFile = Get-ChildItem -Path $packageDirectory -Force -Recurse -File -Filter "*.zip";
        $zipFile | Expand-Archive -Force -DestinationPath $packageDirectory;
        $zipFile | Remove-Item -Recurse -Force -Confirm:$false;
    } -ArgumentList $InstallPackageBuildServerPackageDirectory;
}
function RemoveConfigurationBuildWithoutLast {
    param ([object] $Session)
    Log -Message "Removed old configuration builds";
    Invoke-Command -Session $Session -ScriptBlock {
        Param ($webAppBuildDirectory)
        $removeFolders = Get-ChildItem -Path $webAppBuildDirectory -Directory -Recurse | Sort-Object CreationTime -desc | Select-Object -Skip 1;
        Write-Host $removeFolders;
        $removeFolders | Remove-Item -Recurse -Force -Confirm:$false;
    } -ArgumentList $WebAppConfigurationBuildDirectory;
}
function DownloadConfigurationBuild {
    param ([object] $Session)
    Log -Message "Download configuration buil to local";
    DownloadRemoteFile -Session $sessions -Source ($ConfigurationBinDirectory + "\Terrasoft.Configuration*") -Destination ($LocalConfigurationBinDirectory + "\");
    DownloadRemoteFile -Session $sessions -Source ($WebAppConfigurationDirectory + "\_MetaInfo.json") -Destination ($LocalWebAppBinDirectory + "\");
    DownloadRemoteFile -Session $sessions -Source ($WebAppConfigurationBuildDirectory + "\*") -Destination ($LocalWebAppBinDirectory + "\bin\");
    DownloadRemoteFile -Session $sessions -Source ($WebAppRuntimeDataDirectory + "\*") -Destination ($LocalWebAppRuntimeDataDirectory + "\");
}
function ClearLocalBuildData {
    param ()
    Log -Message "Clear old build local data";
    Get-ChildItem -Path $LocalConfigurationBinDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
    Get-ChildItem -Path $LocalWebAppBinDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
    Get-ChildItem -Path $LocalWebAppRuntimeDataDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
}
function InstallPackage {
    param ()
    Log -Message "Start install package";
    ClearLocalBuildData;
    $sessions = CreateSession -ServersIp $InstallPackageBuildServerIp -Login $RemoteUserLogin -Pass $RemoteUserPassword;
    SendPackage -Session $sessions;
    StopServer -Session $sessions;
    if (WSInstallPackage -Session $sessions -PackageDirectory $PackageDirectory -eq -1) {
        Log -Message "Installed WC package with error";
        StartServer -Session $sessions;
        $sessions | Remove-PSSession;
        exit -1;
    }
    RemoveConfigurationBuildWithoutLast -Session $sessions;
    DownloadConfigurationBuild -Session $sessions;
    StartServer -Session $sessions;
    $sessions | Remove-PSSession;
    Log -Message "End install package";
}