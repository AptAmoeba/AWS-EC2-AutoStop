# AWS-EC2-AutoStop
Scheduled task created to automatically stop an EC2 instance by monitoring Event logs for RDP disconnects & pairing them with the associated EC2 account; prudent to reconnects (and reboot safe!).

&nbsp;

## Description
This is a Scheduled task that triggers on Event ID 24 (RDP Disconnect), which runs a powershell script that compares the most recent disconnect user to the EC2 connect user that you specify ($U; Default: Administrator).<br> The script waits for 4 minutes as a grace period to reconnect (auto-aborting if it detects Event ID 25 for $U), otherwise it shuts the EC2 down.  

### Installation:
Download the EC2-AutoStop XML file, then do the following:

1.) Open Task Scheduler<br>
2.) Action > Import Task > Select EC2-AutoStop.xml > Select "OK"<br>

&nbsp;

## Annotated Powershell Script
```Powershell
#-Command "
$U = 'Administrator';
$Fname = $env:COMPUTERNAME + "\" + $U;
$event24 = (Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=24} -MaxEvents 1).message
if ($event24 -contains $Fname) {
	#Wait through grace period
	Start-Sleep -Seconds 240
	
	#Checking for reconnect within grace period
	$event25 = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=25} -MaxEvents 1
	
	if ($event25.Properties[0].Value -eq $Fname -and $event25.TimeCreated -gt (Get-Date).AddMinutes(-4)) {
		Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Reconnected; shutdown aborted', 'EC2-Status')
		#Debug: Write-Output '$U reconnect within grace period detected. Aborting.'
	} else {
		shutdown /s /f /t 20 /c 'Admin rdp disconnect detected; Shutting down.'
		#Debug: Write-Output 'No $U reconnect within grace period. Shutting down.'
	}
}
#"
```

&nbsp;

## Task XML:
(Included for curious folk)
<details>
  <summary>XML Code</summary>

    <?xml version="1.0" encoding="UTF-16"?>
	<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
	  <RegistrationInfo>
	    <Date>2024-04-20T16:20:10.6969696</Date>
	    <Author>Administrator</Author>
	    <Description>Automatic Stop-Instance switch for AWS after rdp disconnect.</Description>
	    <URI>\EC2-AutoStop</URI>
	  </RegistrationInfo>
	  <Triggers>
	    <EventTrigger>
	      <StartBoundary>2024-04-20T18:00:00</StartBoundary>
	      <Enabled>true</Enabled>
	      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"&gt;&lt;Select Path="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"&gt;*[System[Provider[@Name='Microsoft-Windows-TerminalServices-LocalSessionManager'] and EventID=24]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
	    </EventTrigger>
	  </Triggers>
	  <Principals>
	    <Principal id="Author">
	      <UserId>S-1-5-21-1115079623-1387137672-2099510147-500</UserId>
	      <LogonType>S4U</LogonType>
	      <RunLevel>HighestAvailable</RunLevel>
	    </Principal>
	  </Principals>
	  <Settings>
	    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
	    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
	    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
	    <AllowHardTerminate>false</AllowHardTerminate>
	    <StartWhenAvailable>true</StartWhenAvailable>
	    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
	    <IdleSettings>
	      <StopOnIdleEnd>true</StopOnIdleEnd>
	      <RestartOnIdle>false</RestartOnIdle>
	    </IdleSettings>
	    <AllowStartOnDemand>false</AllowStartOnDemand>
	    <Enabled>true</Enabled>
	    <Hidden>false</Hidden>
	    <RunOnlyIfIdle>false</RunOnlyIfIdle>
	    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
	    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
	    <WakeToRun>true</WakeToRun>
	    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
	    <Priority>7</Priority>
	  </Settings>
	  <Actions Context="Author">
	    <Exec>
	      <Command>Powershell.exe</Command>
	      <Arguments>-Command "$U = 'Administrator'; $Fname = $env:COMPUTERNAME + '\' + $U; $event24 = (Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=24} -MaxEvents 1).message; if ($event24 -contains $Fname){Start-Sleep -Seconds 240; $event25 = (Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=25} -MaxEvents 1); if ($event25.Properties[0].Value -eq $Fname -and $event.TimeCreated -gt (Get-Date).AddMinutes(-4)){Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Reconnected; shutdown aborted', 'EC2-Status')}else {shutdown /s /f /t 20 /c 'Admin rdp disconnect detected; Shutting down.'}}"</Arguments>
	    </Exec>
	  </Actions>
	</Task>

</details>
