# Active Directory User Logon Report (PowerShell)

This script retrieves a list of Active Directory users who have both a first name (GivenName) and a last name (Surname) assigned.  
It displays their names along with the date of their last successful logon.  
If no logon is recorded, the script will label the user as "Nie angemeldet" (never logged on).

## Features

- Filters out technical accounts without a GivenName or Surname
- Converts `lastLogonTimestamp` to a human-readable datetime
- Replaces missing logon data with a clear fallback message
- Outputs clean tabular data, suitable for further processing

## Requirements

- PowerShell (Windows PowerShell or PowerShell Core)
- Active Directory module (`Get-ADUser` must be available)
- Domain-joined system or appropriate AD remote access

## Usage

Run the script in a PowerShell session with the required permissions:

```powershell
.\Get-ADUser-Logons.ps1