#(This is the beautified version of the one-liner within the <Command>Powershell.exe</Command><arguments>-Command "[PS-CODE]"</arguments> section of the XML import)

#-Command "
$U = 'Administrator'; # Change 'Administrator' to your EC2 Account. (Match the XML code's "<Author>USER</Author> section with this $U value!)
$event24 = (Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=24} -MaxEvents 1).message
if ($event24 -match $U) {
	# Wait
	# Change 240 to whatever grace period you'd like, in seconds.
	Start-Sleep -Seconds 240
	
	# Checking for reconnect within grace period
	$event25 = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; ID=25} -MaxEvents 1
	
	# ".AddMinutes(-4))" = "in the last 4 minutes." match this value with your Start-Sleep value.
	if ($event25.Properties[0].Value -eq $U -and $event25.TimeCreated -gt (Get-Date).AddMinutes(-4)) {
		Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Reconnected; shutdown aborted', 'EC2-Status')
		#Debug: Write-Output '$U reconnect within grace period detected. Aborting.'
	} else {
		shutdown /s /f /t 0 /c 'Admin rdp disconnect detected; Shutting down.'
		#Debug: Write-Output 'No $U reconnect within grace period. Shutting down.'
	}
}
#"