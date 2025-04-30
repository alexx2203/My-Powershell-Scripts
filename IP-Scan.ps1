# Loop through IP addresses from 10.27.2.1 to 10.27.2.254
1..254 | ForEach-Object {
    $ip = "10.27.2.$_"  # Build current IP address

    # Check if the device responds (Ping)
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {

        try {
            # If ping is successful: resolve hostname via DNS
            $name = [System.Net.Dns]::GetHostEntry($ip).HostName
        } catch {
            # If DNS resolution fails
            $name = "Unknown"
        }

        # Output IP + name
        Write-Output "$ip - $name is responding"
    }
}
