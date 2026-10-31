# Retire only the six temporary Next servers created by this Stage 5 run.
# Revalidate each known PID/port before stopping; leave the original dev server and 3007 review server.
$stageServers = @(
    @{ Id=3304; Port=3001 }, @{ Id=1788; Port=3002 },
    @{ Id=25616; Port=3003 }, @{ Id=5244; Port=3004 },
    @{ Id=22160; Port=3005 }, @{ Id=26004; Port=3006 }
)
foreach ($stageServer in $stageServers) {
    $stageProcess = Get-CimInstance Win32_Process -Filter ("ProcessId = " + $stageServer.Id)
    if ($stageProcess -and $stageProcess.CommandLine -match 'next.*start' -and $stageProcess.CommandLine -match ("--port " + $stageServer.Port + '(\s|$)')) {
        Stop-Process -Id $stageServer.Id
        Write-Output ("Closed temporary review server on port " + $stageServer.Port)
    }
}
