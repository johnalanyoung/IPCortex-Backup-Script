#--------------------------------------------------- 
# Script: IPCortexBackup.ps1
# Author: johnalanyoung (http://www.johnyoung.tech)
#---------------------------------------------------

Function Backup-Cortex{
    param  (
            [string] $Customer,
            [string] $IPCortexAddress, 
            [string] $username,
            [string] $password
           )
            $date = Get-Date -Format "yyyy-MM-dd HHmmss" # Creates date and time which can be used for part of the filename
            $date2 = Get-Date -Format "yyyyMd" # Used for downloading voicemail greetings and system logs
            $BackupLocation = "X:\IPCortexBackups" # Root backup location
            $BackupLocationCustomer = "$BackupLocation\$Customer"
            $BackupLocationSysConfig = "$BackupLocationCustomer\1 - System Config and Call Records" # System configuration and call records backup location
            $BackupLocationIVR = "$BackupLocationCustomer\2 - IVR Sound Files" # IVR sound files backup location
            $BackupLocationVMGreet = "$BackupLocationCustomer\3 - Voicemail Greetings" # Voicemail greetings backup location
            $BackupLocationSysLogs = "$BackupLocationCustomer\4 - System Logs" # System logs backup location
            $BackupLocationCallRec = "$BackupLocationCustomer\5 - Call Recordings" # Call recordings backup location
            $tempfile = "$BackupLocation\tmp.txt" # Temporary file filename and location
            $cookie = "$BackupLocation/ipcortex_cookie.txt" # Cookie filename and file location
            $AlertEmailAddress = "[EMAIL ADDRESS HERE]" # Not currently in use
            $tempuser = [System.Net.WebUtility]::UrlEncode($username) # Encodes the username in case special characters are used to ensure complicated usernames work
            $temppassword = [System.Net.WebUtility]::UrlEncode($password) # Encodes the password in case special characters are used to ensure complicated passwords work
            $Wgetlocation = "C:\Program Files (x86)\GnuWin32\bin" # File location for Wget

            cd $Wgetlocation

            Write-Host START OF SCRIPT...

            # Calls on the HTTP/S function check
            HTTPS-Check #Checks if the server is HTTP or HTTPS

            # Sets the correct link for the download depending on the port that is used
            if ($HTTP -gt 0){
            $CortexLoginURL = "http://$IPCortexAddress/login.whtm?sessionUser=$tempuser&sessionPass=$temppassword" # Creates login URL
            $CortexDownloadURL = "http://$IPCortexAddress/admin/backup.whtm/update/backup.tar.gz" # Creates system configuration and call records download URL
            $CortexIVRDownloadURL = "http://$IPCortexAddress/admin/backup.whtm/update/ivr.tar.gz" # Creates IVR sound files download URL
            $CortexVMGreetDownloadURL = "http://$IPCortexAddress/admin/backup.whtm/vmgreet$date2.tar.gz" # Creates voicemail greetings download URL
            $CortexLogDownloadURL = "http://$IPCortexAddress/admin/backup.whtm/logs$date2.tar.gz" # Creates system logs download URL
            $CortexCallRecordingURL = "http://$IPCortexAddress/link/monitor.whtm" # Creates call recordings download URL
            }
            if ($HTTPS -gt 0){
            $CortexLoginURL = "https://$IPCortexAddress/login.whtm?sessionUser=$tempuser&sessionPass=$temppassword" # Creates login URL
            $CortexDownloadURL = "https://$IPCortexAddress/admin/backup.whtm/update/backup.tar.gz" # Creates system configuration and call records download URL
            $CortexIVRDownloadURL = "https://$IPCortexAddress/admin/backup.whtm/update/ivr.tar.gz" # Creates IVR sound files download URL
            $CortexVMGreetDownloadURL = "https://$IPCortexAddress/admin/backup.whtm/vmgreet$date2.tar.gz" # Creates voicemail greetings download URL
            $CortexLogDownloadURL = "https://$IPCortexAddress/admin/backup.whtm/logs$date2.tar.gz" # Creates system logs download URL
            $CortexCallRecordingURL = "https://$IPCortexAddress/link/monitor.whtm" # Creates call recordings download URL
            }

            # Create missing folders
            md -Force "$BackuplocationCustomer"
            md -Force "$BackupLocationSysConfig"
            md -Force "$BackupLocationIVR"
            md -Force "$BackupLocationVMGreet"
            md -Force "$BackupLocationSysLogs"
            md -Force "$BackupLocationCallRec"

            # Debug info:
            Write-Host IF HTTP PASSED INTEGER WILL BE 1. FAILED WILL BE 0. SYSTEM SEES IT AS: $HTTP
            Write-Host IF HTTPS PASSED INTEGER WILL BE 1. FAILED WILL BE 0. SYSTEM SEES IT AS: $HTTPS
            Write-Host IF HTTP AND HTTPS PASSED INTEGER WILL BE 0. FAILED WILL BE 1. SYSTEM SEES IT AS: $FAILED

            if ($FAILED -lt 1){
            Write-Host INITIATING MAIN HTTP OR HTTPS DOWNLOADS...

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
            if ($HTTP -gt 0){
            $CortexCallRecordFileUrl = "http://$IPCortexAddress$CortexCallRecordFile"
            }
            if ($HTTPS -gt 0){
            $CortexCallRecordFileUrl = "https://$IPCortexAddress$CortexCallRecordFile"
            }
            .\wget.exe --no-check-certificate -O $BackupLocationCallRec\"$date-recordings.tar.gz" --max-redirect=1 --load-cookies=$cookie --tries=1 $CortexCallRecordFileUrl

            Write-Host HTTP OR HTTPS DOWNLOAD COMPLETE.
            }

            if ($FAILED -gt 0){
            Write-Host HTTP OR HTTPS DOWNLOADS FAILED. EMAILING TECH SUPPORT NOTIFICATION...
            Send-MailMessage -To [TO EMAIL ADDRESS HERE] -From [FROM EMAIL ADDRESS HERE] -Subject "$Customer - IPCortex Backup Failed" -Body "Customers IPCortex at the following hostname: $CortexAddress has failed to backup over HTTP/HTTPS. Begin diagnostics to troubleshoot further." -SmtpServer [SMTP SERVER HERE]
            }  

            Write-Host END OF SCRIPT

            # Deletes temporary file and cookie
            rm $tempfile
            rm $cookie
            }

Function HTTPS-Check{
            Write-Host HTTP AND HTTPS CHECK HAS INITIATED.
            # HTTP DOWNLOAD CHECK
            Write-Host HTTP LINK IS SET. 
            $CortexLoginURL = "http://$IPCortexAddress"
            Write-Host ATTEMPTING DOWNLOAD OF HTML FILE VIA HTTP...
            .\wget.exe --no-check-certificate -O $tempfile --max-redirect=2 --save-cookies=$cookie --tries=1 $CortexLoginURL

            if ((Get-Content "$tempfile") -eq $Null) {
                $script:HTTP = 0
                Write-Host HTTP FAILED. VALUE SHOULD BE: 0. SYSTEM SEES IT AS: $script:HTTP
            }
            else {
                $script:HTTP = 1
                $script:HTTPS = 0
                $script:FAILED = 0
                Write-Host HTTP PASSED. VALUE SHOULD BE: 1. SYSTEM SEES IT AS: $script:HTTP
            }

            # HTTP DOWNLOAD CHECK
            if ((Get-Content "$tempfile") -eq $Null) {
                Write-Host HTTPS LINK IS SET.
                $CortexLoginURL = "https://$IPCortexAddress"
                Write-Host ATTEMPTING DOWNLOAD OF HTML FILE VIA HTTPS...
                .\wget.exe --no-check-certificate -O $tempfile --max-redirect=2 --save-cookies=$cookie --tries=1 $CortexLoginURL

                if ((Get-Content "$tempfile") -eq $Null) {
                    $script:HTTPS = 0
                    Write-Host HTTPS FAILED. VALUE SHOULD BE: 0. SYSTEM SEES IT AS: $script:HTTPS
                }
                else {
                    $script:HTTPS = 1
                    $script:FAILED = 0
                    Write-Host HTTPS PASSED. VALUE SHOULD BE: 1. SYSTEM SEES IT AS: $script:HTTPS
                }
            }

            # FAILED CHECK
            if ((Get-Content "$tempfile") -eq $Null) {

                if ((Get-Content "$tempfile") -eq $Null) {
                    $script:FAILED = 1
                    $script:HTTPS = 0
                    $script:HTTP = 0
                    Write-Host HTTP AND HTTPS FAILED. VALUE SHOULD BE: 1. SYSTEM SEES IT AS: $script:FAILED
                }
            }
            }

            # Hostname and login credentials for IPCortex stored in seperate csv file. User will need relevant permissions needed to pull backups
            Import-CSV "X:\IPCortexBackups\Project_Files\Main File\ipcortex_list.csv" -Header Customer,Hostname,Username,Password | Foreach-Object{
                Backup-Cortex -Customer $_.Customer -IPCortexAddress $_.Hostname -username $_.Username -password $_.Password
            }
