# IPCortex-Backup-Script
This script remotely downloads backup files from an IPCortex PABX.

## Prerequisites
Powershell - To run the script.

Wget - To download the files over HTTP/HTTPS.

.Net - This is used to fix an issue with passwords with special characters.

## Features

Downloads all backups for multiple units over HTTP/HTTPS.

Attempts alternative protocol when connection is not available.

If backups fail, notification is sent via email.

Stores multiple backups for multiple units in structured directories.

Fully customizable.

Can be integrated into Windows Task Scheduler.

Supported to version 6.1.6.

## Future Improvements

Better handling of empty VM backups.

Compatible with HA environments.

## Notes
Call recordings natively exprire after 21 days on IPCortex HDD. This cannot be changed.

## Acknowledgments
Ainsey11

Salmon85
