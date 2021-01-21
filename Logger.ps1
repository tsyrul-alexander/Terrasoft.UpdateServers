. .\Config.ps1
$LogDirectory = GetConfigValue -Key "LogDirectory";

function GetLogFilePath {
    [OutputType([string])]
    param ()
    $dateStr = Get-Date -Format "dd_MM_yyyy";
    $fileName = $dateStr + ".log";
    return Join-Path -Path $LogDirectory -ChildPath $fileName; 
}
function GetMessageText {
    [OutputType([string])]
    param ([string]$Message)
    $dateStr = Get-Date -Format "dd-MM-yyyy HH:mm:ss";
    return $dateStr + " " + $Message;
}
function Log {
    param ([string]$Message)
    $logFilePath = GetLogFilePath;
    $content = GetMessageText -Message $Message;
    Write-Host $content;
    Add-Content -Path $logFilePath -Value $content;
}