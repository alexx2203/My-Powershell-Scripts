# Subnet Scanner Script

This PowerShell script scans a local subnet, pings each IP address, and attempts to resolve its hostname via DNS.

## Features

- Iterates over IP range
- Checks availability using `Test-Connection` (ping)
- Resolves hostname using .NET's DNS resolver
- Outputs results in a simple format to the console

## Requirements

- PowerShell (Windows)
- Network can be changed.
- DNS resolution configured for reachable devices

## Usage

1. Open PowerShell.
2. Run the script.
3. Watch the output: reachable devices and their hostnames (or "Unknown" if DNS fails).

## Example Output

```
10.27.2.1 - router.local is responding
10.27.2.22 - printer.office.local is responding
10.27.2.45 - Unknown is responding
```

## Notes

- Devices that do not respond to ICMP (ping) will be skipped.
- DNS resolution may fail for some IPs, resulting in the label "Unknown".

---

*Perfect for a quick sweep of your local network.* 🕵️‍♀️
