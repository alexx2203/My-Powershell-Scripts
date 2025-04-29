# PC Activity Export Script

This PowerShell script collects Active Directory (AD) computer objects filtered by specific criteria, displays the results, and optionally exports them into a CSV file.

## Features

- Retrieves all AD computer objects
- Filters for:
  - Computers located in `OU=GPO-Computer`
  - Operating Systems matching Windows 10
- Displays key attributes:
  - Name
  - Last Logon Date
  - Creation Date in AD
  - Operating System
- User-friendly prompts:
  - Option to preview data in an interactive GridView
  - Option to export data to a timestamped CSV file
- Automatically creates the export folder if it does not exist

## Requirements

- Windows environment
- PowerShell
- Active Directory module installed (`Get-ADComputer` cmdlet available)
- Access rights to query AD

## Usage

1. **Run the script in PowerShell**.
2. **Choose** whether you want to view the results.
   - If yes, a GridView window will open.
3. **Choose** whether you want to export the results.
   - If yes, a CSV file will be created at `C:\Temp\Activity\` with the current date and time in the filename.

## Notes

- The script ensures better clarity by clearing the console at the beginning.
- If the export folder `C:\Temp\Activity` does not exist, it will be created automatically.
- The CSV uses UTF-8 encoding and a semicolon (`;`) as a delimiter.

## Example Output

The resulting CSV will contain columns like:

| Name | Last Logon | Created In AD | Operating System |
|:----|:-----------|:--------------|:----------------|
| PC001 | 2025-04-29 | 2021-07-15 | Windows 10 Pro |
