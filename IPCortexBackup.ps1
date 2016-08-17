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
            $cookie = "$BackupLocation/johnalanyoung_ipcortex_cookie.txt" # Cookie filename and file location
            $tempuser = [System.Net.WebUtility]::UrlEncode($username) # Encodes the username in case special characters are used to ensure complicated usernames work
            $temppassword = [System.Net.WebUtility]::UrlEncode($password) # Encodes the password in case special characters are used to ensure complicated passwords work
            $CortexLoginURL = "http://$CortexAddress/login.whtm?sessionUser=$tempuser&sessionPass=$temppassword" # Creates login URL
            $CortexDownloadURL = "http://$CortexAddress/admin/backup.whtm/update/backup.tar.gz" # Creates system configuration and call records download URL
            $CortexIVRDownloadURL = "http://$CortexAddress/admin/backup.whtm/update/ivr.tar.gz" # Creates IVR sound files download URL
            $CortexVMGreetDownloadURL = "http://$CortexAddress/admin/backup.whtm/vmgreet$date2.tar.gz" # Creates voicemail greetings download URL
            $CortexLogDownloadURL = “http://$CortexAddress/admin/backup.whtm/logs$date2.tar.gz” # Creates system logs download URL
            $CortexCallRecordingURL = "http://$CortexAddress/link/monitor.whtm" # Creates call recordings download URL
            $Wgetlocation = "C:\Program Files (x86)\GnuWin32\bin" # File location for Wget

            cd $Wgetlocation

            # Starts first download and logs into IPCortex
            .\wget.exe -O $tempfile --max-redirect=1 --save-cookies=$cookie --tries=1 $CortexLoginURL
            
            # Downloads live update of system configuration and call records
            .\wget.exe -O $BackupLocationSysConfig\$date.tar.gz --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexDownloadURL

            # Downloads IVR sound files
            .\wget.exe -O $BackupLocationIVR\"$date-ivr.tar.gz" --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexIVRDownloadURL

            # Downloads voicemail greetings
            .\wget.exe -O $BackupLocationVMGreet\$date-vmgreet.tar.gz --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexVMGreetDownloadURL

            # Downloads system logs
            .\wget.exe -O $BackupLocationSysLogs\$date-logs.tar.gz --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexLogDownloadURL

            # Downloads call recordings
            .\wget.exe -O $tempfile --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexCallRecordingURL
            $CortexCallRecordFile = (gc $tempfile | % { if($_ -match "_default.cgi/recorded.tar.gz") {$_.substring(13,$_.length-13-37)}})
            $CortexCallRecordFileUrl = "http://$CortexAddress$CortexCallRecordFile"
            .\wget.exe -O $BackupLocationCallRec\"$date-recordings.tar.gz" --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexCallRecordFileUrl

            # Deletes temporary file and cookie
            rm $tempfile
            rm $cookie
            }

            # Hostname and login credentials for IPCortex. User will need relevant permissions needed to pull backups
            Backup-Cortex -CortexAddress "hostname" -username "username" -password 'password'
