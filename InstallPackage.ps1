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
[string]$WebAppRuntimeDataDirectory = Join-Path -Path $WebAppDirectory -ChildPath "conf\runtime-data";
[string]$WebAppConfigurationBuildDirectory = Join-Path -Path $WebAppDirectory -ChildPath "conf\bin";
[string]$LocalConfigurationBinDirectory = GetConfigValue -Key "ConfigurationBinDirectory";
[string]$LocalWebAppRuntimeDataDirectory = GetConfigValue -Key "WebAppRuntimeDataDirectory";
[string]$LocalWebAppBinDirectory = GetConfigValue -Key "WebAppBinDirectory";
function SendPackage {
    param ([object] $Session, [string]$PackagePath)
    $distination = $InstallPackageBuildServerPackageDirectory + "\";
    Log -Message "Send package from $PackagePath to $distination";
    SendRemoteFile -Session $sessions -Source $PackagePath -Destination $distination;
}
function RemoveConfigurationBuildWithoutLast {
    param ([object] $Session)
    Log -Message "Removed old configuration builds";
    $commandOutput = Invoke-Command -Session $Session -ScriptBlock {
        Param ($webAppBuildDirectory)
        $removeFolders = Get-ChildItem -Path $webAppBuildDirectory -Directory -Recurse | Sort-Object CreationTime -desc | Select-Object -Skip 1;
        Write-Host $removeFolders;
        $removeFolders | Remove-Item -Recurse -Force -Confirm:$false;
    } -ArgumentList $WebAppConfigurationBuildDirectory;
    Log -Message $commandOutput;
}
function DownloadConfigurationBuild {
    param ([object] $Session)
    Log -Message "Download configuration buil to local";
    DownloadRemoteFile -Session $sessions -Source ($ConfigurationBinDirectory + "\Terrasoft.Configuration*") -Destination ($LocalConfigurationBinDirectory + "\");
    DownloadRemoteFile -Session $sessions -Source ($WebAppConfigurationBuildDirectory + "\*") -Destination ($LocalWebAppBinDirectory + "\");
    DownloadRemoteFile -Session $sessions -Source ($WebAppRuntimeDataDirectory + "\*") -Destination ($LocalWebAppRuntimeDataDirectory + "\");
}
function DownloadRuntimeData {
    param ([object] $Session)
    $source = $WebAppRuntimeDataDirectory + "\*";
    $distination = $LocalWebAppRuntimeDataDirectory + "\";
    Log -Message "Download runtime data from $source to $distination";
    DownloadRemoteFile -Session $sessions -Source $source -Destination $distination;
}
function ClearLocalBuildData {
    param ()
    Log -Message "Clear old build local data";
    Get-ChildItem -Path $LocalConfigurationBinDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
    Get-ChildItem -Path $LocalWebAppBinDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
    Get-ChildItem -Path $LocalWebAppRuntimeDataDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
}
function InstallPackage {
    param ([string]$PackagePath)
    Log -Message "Start install package";
    ClearLocalBuildData;
    $sessions = CreateSession -ServersIp $InstallPackageBuildServerIp -Login $RemoteUserLogin -Pass $RemoteUserPassword;
    SendPackage -Session $sessions -PackagePath $PackagePath;
    StopServer -Sessions $sessions;
    #if (WSInstallPackage -Session $sessions -PackageDirectory $PackageDirectory -eq -1) {
    #    Log -Message "Installed WC package with error";
    #    StartServer -Sessions $sessions;
    #    $sessions | Remove-PSSession;
    #    exit -1;
    #}
    RemoveConfigurationBuildWithoutLast -Session $sessions;
    DownloadConfigurationBuild -Session $sessions;
    DownloadRuntimeData -Session $sessions;
    StartServer -Sessions $sessions;
    $sessions | Remove-PSSession;
    Log -Message "End install package";
}