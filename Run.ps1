. .\Config.ps1
. .\Logger.ps1
$PackageDirectory = GetConfigValue -Key "PackageDirectory";

function GetPackagePath {
    [OutputType([bool])]
    param()
    $firstFile = Get-ChildItem -Path $PackageDirectory -Force -Recurse -File -Filter "*.zip" | Select-Object -First 1;
    if ($null -eq $firstFile) {
        return $null;
    }
    return $firstFile.FullName;
}

function Main {
    Log -Message "Start";
    $packagePath = GetPackagePath;
    if ($null -eq $packagePath) {
        Log -Message "Package not found in $PackageDirectory";
        return;
    }
    InstallPackage;
    Log -Message "End";
}
Main;