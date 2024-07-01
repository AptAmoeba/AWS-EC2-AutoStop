#(This is the beautified version of the one-liner within the <Command>Powershell.exe</Command><arguments>-Command "[PS-CODE]"</arguments> section of the XML import)

#-Command "
$U = 'Administrator';
$Fname = $env:COMPUTERNAME + "\" + $U;
$event24 = (Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=24} -MaxEvents 1)
if ($event24.Properties[0].Value -eq $Fname) {
	#Wait through grace period
	Start-Sleep -Seconds 240
	
	#Checking for reconnect within grace period
	$event25 = (Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=25} -MaxEvents 1)
	
	if ($event25.Properties[0].Value -eq $Fname -and $event25.TimeCreated -gt (Get-Date).AddMinutes(-4)) {
		Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Reconnected; shutdown aborted', 'EC2-Status')
		#Debug: Write-Output '$U reconnect within grace period detected. Aborting.'
	} else {
		shutdown /s /f /t 20 /c 'Admin rdp disconnect detected; Shutting down.'
		#Debug: Write-Output 'No $U reconnect within grace period. Shutting down.'
	}
}
#"
