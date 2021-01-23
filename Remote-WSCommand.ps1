. .\Config.ps1;
. .\Logger.ps1;
[string]$LoaderDirectory = GetConfigValue -Key "InstallPackageServerLoaderDirectory";
[string]$WebAppDirectory = Join-Path -Path $LoaderDirectory -ChildPath "Terrasoft.WebApp";
[string]$WCPath = Join-Path -Path $WebAppDirectory -ChildPath "DesktopBin\WorkspaceConsole\Terrasoft.Tools.WorkspaceConsole.exe";
[string]$InstallPackageBuildServerPackageDirectory = GetConfigValue -Key "InstallPackageBuildServerPackageDirectory";
[string]$InstallPackageBuildServerPackageTempDirectory = GetConfigValue -Key "InstallPackageBuildServerPackageTempDirectory";
[string]$InstallPackageServerWCLogDirectory = GetConfigValue -Key "InstallPackageServerWCLogDirectory";

function WSLogCommand {
    param ([int]$ErrorCode, [string]$Message)
    if ($exitCode -eq -1) {
        Log -Message $output;
    }
}

function WSInstallPackage {
    param ([object]$Session, [string]$PackageDirectory)
    Log -Message "WC start install package";
    $output = Invoke-Command -Session $Session -ScriptBlock {
        Param ($wcPath, $loaderPath, $webAppPath, $packageDirectory, $packageTempDirectory, $logPath)
        Write-Host $wcPath -operation=InstallFromRepository -workspaceName=Default  -updateSystemDBStructure=true -installPackageSqlScript=true -installPackageData=true "-sourcePath=$packageDirectory" "-destinationPath=$packageTempDirectory" "-webApplicationPath=$loaderPath" "-confRuntimeParentDirectory=$webAppPath" -clearWorkspace=false -continueIfError=true "-logPath=$logPath" -autoExit=true;
        Get-ChildItem -Path $packageTempDirectory -Directory -Recurse | Remove-Item -Recurse -Force -Confirm:$false;
        & $wcPath -operation=InstallFromRepository -workspaceName=Default  -updateSystemDBStructure=true -installPackageSqlScript=true -installPackageData=true "-sourcePath=$packageDirectory" "-destinationPath=$packageTempDirectory" "-webApplicationPath=$loaderPath" "-confRuntimeParentDirectory=$webAppPath" -clearWorkspace=false -continueIfError=true "-logPath=$logPath" -autoExit=true;
    } -ArgumentList $WCPath, $LoaderDirectory, $WebAppDirectory, $InstallPackageBuildServerPackageDirectory, $InstallPackageBuildServerPackageTempDirectory, $InstallPackageServerWCLogDirectory;
    $exitCode = Invoke-command -ScriptBlock { $lastexitcode} -Session $Session;
    WSLogCommand -ErrorCode $exitCode -Message $output;
    return $exitCode;
}

function WCBuildConfiguration {
    param ([object]$Session)
    Log -Message "WC start Build configuration";
    $output = Invoke-Command -Session $Session -ScriptBlock {
        Param ($wcPath, $loaderPath, $webAppPath, $logPath)
        & $wcPath -operation=BuildConfiguration -workspaceName=Default "-destinationPath=$webAppPath" "-webApplicationPath=$loaderPath" "-confRuntimeParentDirectory=$webAppPath" -clearWorkspace=false -continueIfError=true "-logPath=$logPath" -force=true -autoExit=true;
    } -ArgumentList $WCPath, $LoaderDirectory, $WebAppDirectory, $InstallPackageServerWCLogDirectory;
    $exitCode = Invoke-command -ScriptBlock { $lastexitcode} -Session $Session;
    WSLogCommand -ErrorCode $exitCode -Message $output;
    return $exitCode;
}