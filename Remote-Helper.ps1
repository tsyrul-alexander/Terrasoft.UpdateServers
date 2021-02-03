function SendRemoteFile {
    param([object] $Session, [string] $Source, [string] $Destination)
    Copy-Item $Source -Destination $Destination -ToSession $Session -recurse -force;
}
function DownloadRemoteFile {
    param([object] $Session, [string] $Source, [string] $Destination)
    Copy-Item $Source -Destination $Destination -FromSession $Session -recurse -force;
}
function StopServer {
    param ([object]$Session)
    Invoke-Command -Session $Session -ScriptBlock {
        iisreset /stop
    }
}
function StartServer {
    param ([object]$Session)
    Invoke-Command -Session $Session -ScriptBlock {
        iisreset /start
    }
}
function CreateSession {
    [OutputType([System.Management.Automation.Runspaces.PSSession[]])]
    param([String[]]$ServersIp, [string]$Login, [string]$Pass)
    $sessions = @();
    $securePass = ConvertTo-SecureString -String $Pass -AsPlainText -Force;
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $securePass;
    foreach($serverId in $ServersIp) {
        $s = New-PSSession -ComputerName $serverId -Credential $credential;
        $sessions += $s;
    }
    return [System.Management.Automation.Runspaces.PSSession[]]$sessions;
}