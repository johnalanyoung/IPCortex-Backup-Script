#--------------------------------------------------- 
# Script: IPCortexBackup.ps1
# Author: johnalanyoung (http://johnalanyoung.com)
#--------------------------------------------------- 

Function Backup-Cortex{
    param  (
            [string] $CortexAddress, 
            [string] $username,
            [string] $password
           )
            # Static variables:
            $date = Get-Date -Format "yyyy-MM-dd HHmmss" # Creates date and time which can be used for part of the filename
            $BackupLocation = "X:\IPCortexBackups" # Root backup location
            $tempfile = "$BackupLocation\tmp.txt" # Temporary file filename and location
            $cookie = "$BackupLocation/johnalanyoung_ipcortex_cookie.txt" # Cookie filename and file location
            $tempuser = [System.Net.WebUtility]::UrlEncode($username) # Encodes the username in case special characters are used to ensure complicated usernames work
            $temppassword = [System.Net.WebUtility]::UrlEncode($password) # Encodes the password in case special characters are used to ensure complicated passwords work
            $Wgetlocation = "C:\Program Files (x86)\GnuWin32\bin" # File location for Wget

            cd $Wgetlocation

            # Starts first download and logs into IPCortex
            Httpscheck #Checks if the server is http or https
			
			if ($Https = 1){
			$CortexDownloadURL = "https://$CortexAddress/admin/backup.whtm/update/backup.tar.gz" # Creates system configuration and call records download URL
            $CortexIVRDownloadURL = "https://$CortexAddress/admin/backup.whtm/update/ivr.tar.gz" # Creates IVR sound files download URL
            $CortexVMGreetDownloadURL = "https://$CortexAddress/admin/backup.whtm/vmgreet$date2.tar.gz" # Creates voicemail greetings download URL
            $CortexLogDownloadURL = "https://$CortexAddress/admin/backup.whtm/logs$date2.tar.gz" # Creates system logs download URL
            $CortexCallRecordingURL = "https://$CortexAddress/link/monitor.whtm" # Creates call recordings download URL
			}
			
			if ($Https = 0){
			$CortexDownloadURL = "http://$CortexAddress/admin/backup.whtm/update/backup.tar.gz" # Creates system configuration and call records download URL
            $CortexIVRDownloadURL = "http://$CortexAddress/admin/backup.whtm/update/ivr.tar.gz" # Creates IVR sound files download URL
            $CortexVMGreetDownloadURL = "http://$CortexAddress/admin/backup.whtm/vmgreet$date2.tar.gz" # Creates voicemail greetings download URL
            $CortexLogDownloadURL = "http://$CortexAddress/admin/backup.whtm/logs$date2.tar.gz" # Creates system logs download URL
            $CortexCallRecordingURL = "http://$CortexAddress/link/monitor.whtm" # Creates call recordings download URL
			}
			
			
			#Check to see if we can login
			
			gc $tempfile | % { if($_ -match "<title>Login Page</title>") {
			Write-Output "FAILED TO LOG INTO $Customer ipcortex"
			Write-Output "Emailing $AlertEmailAddress with notification"
			Send-MailMessage -To $AlertEmailAddress -From Cortexbackup@timico.co.uk -Subject "$CortexAddress failed to login" -Body "$CortexAddress failed to login, please check log in credentials" -SmtpServer relay.mail.timico.net
			$failed = 1
			}
			}
			
			
            #More downloads
			if (-Not $failed){
			$Custtemp = gc $tempfile | out-string
			$Custtempstart = $Custtemp.indexOf("<h2>") + 4
			$Custtempend = $Custtemp.indexOf("</h2>", $Custtempstart)
			$Custtemplength = $Custtempend - $Custtempstart
			$Customer = $Custtemp.substring($Custtempstart, $Custtemplength)
			Write-Output "$Customer"
			$BackupLocationCustomer = "$BackupLocation\$Customer"
            $BackupLocationSysConfig = "$BackupLocationCustomer\1 - System Config and Call Records" # System configuration and call records backup location
            $BackupLocationIVR = "$BackupLocationCustomer\2 - IVR Sound Files" # IVR sound files backup location
            $BackupLocationVMGreet = "$BackupLocationCustomer\3 - Voicemail Greetings" # Voicemail greetings backup location
            $BackupLocationSysLogs = "$BackupLocationCustomer\4 - System Logs" # System logs backup location
            $BackupLocationCallRec = "$BackupLocationCustomer\5 - Call Recordings" # Call recordings backup location
			
			#Write-Output "$BackuplocationCustomer"
			#Write-Output "$BackupLocationSysConfig"
			#Write-Output "$BackupLocationIVR"
			#Write-Output "$BackupLocationVMGreet"
			#Write-Output "$BackupLocationSysLogs"
			#Write-Output "$BackupLocationCallRec"
			
			# Create missing folders
			md -Force "$BackuplocationCustomer"
			md -Force "$BackupLocationSysConfig"
			md -Force "$BackupLocationIVR"
			md -Force "$BackupLocationVMGreet"
			md -Force "$BackupLocationSysLogs"
			md -Force "$BackupLocationCallRec"
            
            # Downloads live update of system configuration and call records
            .\wget.exe --no-check-certificate -O $BackupLocationSysConfig\$date.tar.gz --max-redirect=5 --load-cookies=$cookie --tries=1 $CortexDownloadURL

            # Downloads IVR sound files
            .\wget.exe --no-check-certificate -O $BackupLocationIVR\"$date-ivr.tar.gz" --max-redirect=5 --load-cookies=$cookie --tries=1 $CortexIVRDownloadURL

            # Downloads voicemail greetings
            .\wget.exe --no-check-certificate -O $BackupLocationVMGreet\$date-vmgreet.tar.gz --max-redirect=5 --load-cookies=$cookie --tries=1 $CortexVMGreetDownloadURL

            # Downloads system logs
            .\wget.exe --no-check-certificate -O $BackupLocationSysLogs\$date-logs.tar.gz --max-redirect=5 --load-cookies=$cookie --tries=1 $CortexLogDownloadURL

            # Downloads call recordings
            .\wget.exe --no-check-certificate -O $tempfile --max-redirect=5 --load-cookies=$cookie --tries=1 $CortexCallRecordingURL
            $CortexCallRecordFile = (gc $tempfile | % { if($_ -match "_default.cgi/recorded.tar.gz") {$_.substring(13,$_.length-13-37)}})
            if ($Https = 0){
			$CortexCallRecordFileUrl = "http://$CortexAddress$CortexCallRecordFile"
			}
			if ($Https = 1){
			$CortexCallRecordFileUrl = "https://$CortexAddress$CortexCallRecordFile"
			}
            .\wget.exe -O $BackupLocationCallRec\"$date-recordings.tar.gz" --max-redirect=5 --load-cookies=$cookie --tries=1 $CortexCallRecordFileUrl

            # Deletes temporary file and cookie
            rm $tempfile
            rm $cookie
            }
			}

            # Hostname and login credentials for IPCortex. User will need relevant permissions needed to pull backups
            
			
			Function Httpscheck($Https){
			#Check on Http
			$CortexLoginURL = "http://$CortexAddress/login.whtm?sessionUser=$tempusername&sessionPass=$temppassword" # Creates login URL
			.\wget.exe --no-check-certificate -O $tempfile --max-redirect=5 --save-cookies=$cookie --tries=1 $CortexLoginURL
			If ((Get-Content "$tempfile") -eq $Null){
			Write-Output "Unable to access $Customer ipcortex on Http... Testing on Https"
			
			#Check on https
			$CortexLoginURL = "https://$CortexAddress/login.whtm?sessionUser=$tempusername&sessionPass=$temppassword" # Creates login URL
			.\wget.exe --no-check-certificate -O $tempfile --max-redirect=5 --save-cookies=$cookie --tries=1 $CortexLoginURL
			If ((Get-Content "$tempfile") -eq $Null){
			Write-Output "Unable to access $Customer ipcortex on Https... Is it down?"
			Send-MailMessage -To $AlertEmailAddress -From Cortexbackup@timico.co.uk -Subject "$CortexAddress failed to connect" -Body "$CortexAddress failed to connect. Is it down?" -SmtpServer relay.mail.timico.net
			$failed = 1
			}
			$Https = 1
			}
			$Https = 0
			}
			
Import-CSV U:\ipcortexbackups\cortex.csv -Header Server,User,Pass,Customer | Foreach-Object{
  Backup-Cortex -CortexAddress $_.Server -username $_.User -password $_.Pass
}
