$ConfigFileName = "config.json";
function GetConfigObject {
    [OutputType([Object])]
    param ()
    $configStr = Get-Content -Path $ConfigFileName;
    return $configStr | ConvertFrom-Json;
}
$ConfigObject = GetConfigObject;
function GetConfigValue {
    [OutputType([string])]
    param ([string]$Key)
    return $ConfigObject.$Key;
}
