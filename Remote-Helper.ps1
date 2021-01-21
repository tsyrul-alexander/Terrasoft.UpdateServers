function SendRemoteFile {
    param([object] $Session, [string] $Source, [string] $Destination)
    Copy-Item $Source -Destination $Destination -ToSession $Session;
}
function CreateSession {
    [OutputType([System.Management.Automation.Runspaces.PSSession[]])]
    param([String[]]$ServersIp, [string]$Login, [string]$Pass)
    $sessions = @()
    $securePass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $securePass
    foreach($serverId in $ServersIp) {
        $s = New-PSSession -ComputerName $serverId -Credential $credential
        $sessions += $s
    }
    return [System.Management.Automation.Runspaces.PSSession[]]$sessions
}