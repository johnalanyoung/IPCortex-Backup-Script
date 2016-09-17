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
            $date2 = Get-Date -Format "yyyyMd" # Used for downloading voicemail greetings and system logs
            $BackupLocation = "X:\IPCortexBackups" # Root backup location
            $BackupLocationSysConfig = "X:\IPCortexBackups\1 - System Config and Call Records" # System configuration and call records backup location
            $BackupLocationIVR = "X:\IPCortexBackups\2 - IVR Sound Files" # IVR sound files backup location
            $BackupLocationVMGreet = "X:\IPCortexBackups\3 - Voicemail Greetings" # Voicemail greetings backup location
            $BackupLocationSysLogs = "X:\IPCortexBackups\4 - System Logs" # System logs backup location
            $BackupLocationCallRec = "X:\IPCortexBackups\5 - Call Recordings" # Call recordings backup location
            $tempfile = "$BackupLocation\tmp.txt" # Temporary file filename and location
            $cookie = "$BackupLocation/ipcortex_cookie.txt" # Cookie filename and file location
            $tempuser = [System.Net.WebUtility]::UrlEncode($username) # Encodes the username in case special characters are used to ensure complicated usernames work
            $temppassword = [System.Net.WebUtility]::UrlEncode($password) # Encodes the password in case special characters are used to ensure complicated passwords work
            $Wgetlocation = "C:\Program Files (x86)\GnuWin32\bin" # File location for Wget

            cd $Wgetlocation

            # Calls on the HTTP/S function check
            HTTPS-Check #Checks if the server is HTTP or HTTPS

            # Sets the correct link for the download depending on the port that is used
            if ($Https = 1){
            $CortexLoginURL = "https://$CortexAddress/login.whtm?sessionUser=$tempuser&sessionPass=$temppassword" # Creates login URL
            $CortexDownloadURL = "https://$CortexAddress/admin/backup.whtm/update/backup.tar.gz" # Creates system configuration and call records download URL
            $CortexIVRDownloadURL = "https://$CortexAddress/admin/backup.whtm/update/ivr.tar.gz" # Creates IVR sound files download URL
            $CortexVMGreetDownloadURL = "https://$CortexAddress/admin/backup.whtm/vmgreet$date2.tar.gz" # Creates voicemail greetings download URL
            $CortexLogDownloadURL = "https://$CortexAddress/admin/backup.whtm/logs$date2.tar.gz" # Creates system logs download URL
            $CortexCallRecordingURL = "https://$CortexAddress/link/monitor.whtm" # Creates call recordings download URL
            }
            if ($Https = 0){
            $CortexLoginURL = "http://$CortexAddress/login.whtm?sessionUser=$tempuser&sessionPass=$temppassword" # Creates login URL
            $CortexDownloadURL = "http://$CortexAddress/admin/backup.whtm/update/backup.tar.gz" # Creates system configuration and call records download URL
            $CortexIVRDownloadURL = "http://$CortexAddress/admin/backup.whtm/update/ivr.tar.gz" # Creates IVR sound files download URL
            $CortexVMGreetDownloadURL = "http://$CortexAddress/admin/backup.whtm/vmgreet$date2.tar.gz" # Creates voicemail greetings download URL
            $CortexLogDownloadURL = "http://$CortexAddress/admin/backup.whtm/logs$date2.tar.gz" # Creates system logs download URL
            $CortexCallRecordingURL = "http://$CortexAddress/link/monitor.whtm" # Creates call recordings download URL
            }

            # The Downloads:
            # Starts first download and logs into IPCortex - Requires 2 max re-directs over http/s
            .\wget.exe --no-check-certificate -O $tempfile --max-redirect=2 --save-cookies=$cookie --tries=1 $CortexLoginURL
            # Downloads live update of system configuration and call records - Requires 1 max re-directs over http/s
            .\wget.exe --no-check-certificate -O $BackupLocationSysConfig\$date.tar.gz --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexDownloadURL
            # Downloads IVR sound files - Requires 1 max re-directs over http/s
            .\wget.exe --no-check-certificate -O $BackupLocationIVR\"$date-ivr.tar.gz" --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexIVRDownloadURL
            # Downloads voicemail greetings - Requires 1 max re-directs over http/s
            .\wget.exe --no-check-certificate -O $BackupLocationVMGreet\$date-vmgreet.tar.gz --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexVMGreetDownloadURL
            # Downloads system logs - Requires 1 max re-directs over http/s
            .\wget.exe --no-check-certificate -O $BackupLocationSysLogs\$date-logs.tar.gz --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexLogDownloadURL
            # Downloads call recordings - Requires 1 max re-directs over http/s
            .\wget.exe --no-check-certificate -O $tempfile --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexCallRecordingURL
            $CortexCallRecordFile = (gc $tempfile | % { if($_ -match "_default.cgi/recorded.tar.gz") {$_.substring(13,$_.length-13-37)}})
            $CortexCallRecordFileUrl = "http://$CortexAddress$CortexCallRecordFile"
            .\wget.exe -O $BackupLocationCallRec\"$date-recordings.tar.gz" --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexCallRecordFileUrl

            # Deletes temporary file and cookie
            rm $tempfile
            rm $cookie
            }

Function HTTPS-Check($Https){
            # Tries a download via HTTP access
            $CortexLoginURL = "http://$CortexAddress/login.whtm?sessionUser=$tempuser&sessionPass=$temppassword" # Creates login URL
            # Starts first download and logs into IPCortex - Requires 2 max re-directs over http/s
            .\wget.exe --no-check-certificate -O $tempfile --max-redirect=2 --save-cookies=$cookie --tries=1 $CortexLoginURL
	
            # If nothing was downloaded over HTTP, it attempts HTTPS access
            If ((Get-Content "$tempfile") -eq $Null){

            # Tries a download via HTTPS access
            $CortexLoginURL = "https://$CortexAddress/login.whtm?sessionUser=$tempuser&sessionPass=$temppassword" # Creates login URL
            # Starts first download and logs into IPCortex - Requires 2 max re-directs over http/s			
            .\wget.exe --no-check-certificate -O $tempfile --max-redirect=2 --save-cookies=$cookie --tries=1 $CortexLoginURL

            # If nothing was downloaded over HTTPS, do nothing (this will be expanded upon in future)
            If ((Get-Content "$tempfile") -eq $Null){
	
            # If both HTTP/HTTPS have failed set integer to 1 for Parameter $failed
            $failed = 1
            }
            # If HTTPS succedded set integer to 1 for Parameter $Https
            $Https = 1
            }
            # If HTTP succedded set integer to 0 for Parameter $Https
            $Https = 0
            }

            # Hostname and login credentials for IPCortex stored in seperate csv file. User will need relevant permissions needed to pull backups
            Import-CSV "X:\IPCortexBackups\Project_Files\Main File\ipcortex_list.csv" -Header IP1,IP2,IP3 | Foreach-Object{
                Backup-Cortex -CortexAddress $_.IP1 -username $_.IP2 -password $_.IP3
            }
