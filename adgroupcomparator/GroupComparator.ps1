# Clear the console
cls

# Create a hashtable to store group DistinguishedNames (DNs) and their corresponding names
$groups = @{}

# Retrieve all Active Directory groups with their DN, Name, and GroupCategory properties
# Filter only for "Security" groups
$groupArray = Get-ADGroup -Filter * -Properties DistinguishedName, Name, GroupCategory |
    Select-Object -Property DistinguishedName, Name, GroupCategory |
    Where-Object { $_.GroupCategory -eq "Security" }

# Populate the hashtable: DN as key, group name as value
foreach ($group in $groupArray) {
    $groups[$group.DistinguishedName] = "$($group.Name)"
}

# Create a flexible list to store user objects
$users = New-Object System.Collections.ArrayList

# Ask how many users should be compared
$neededUsers = Read-Host("How many users would you like to compare?")

# Loop to collect each user based on user input
for ($i = 1; $i -le $neededUsers; $i++) {
    &{
        # Ask for the username input
        $user = Read-Host("Enter user number $($i)")

        try {
            # Try to get the AD user with their name and group memberships (MemberOf)
            $users.Add(
                Get-ADUser -Identity $user -Properties Name, MemberOf |
                Select-Object -Property Name, MemberOf
            )
        }
        catch {
            # Handle case where user is not found
            Write-Host("The user $user was not found.")
        }
    }
}

# Loop through each user and display group membership
foreach ($user in $users) {
    Write-Host ("User: $($user.Name)")
    Write-Host ("Number of groups: {0}" -f $user.MemberOf.Count)
    Write-Host "Groups:"

    # Loop through each group DN and write the corresponding group name
    foreach ($dn in $user.MemberOf) {
<<<<<<< Updated upstream
        Write-Host ("- {0}" -f $groups[$dn])
=======
        Write-Host ("- {0}" -f $groups[$dn])   
    }
    Write-Host("")
}

# Initialize an empty array to store group information per user
$userGroupArray = @()

# Loop through each user up to the count of $neededUsers
for($i=0; $i -lt $neededUsers; $i++){
    # Check if the user has no group memberships
    if(($users[$i].MemberOf -eq $null) -or ($users[$i].MemberOf.Count -eq 0)){
        # Add the string "no groups" if the user is not a member of any group
        $userGroupArray += "no groups"
    }else{
        # Otherwise, add the list of groups the user belongs to
        $userGroupArray += $users[$i].MemberOF
    } 
}

# Display the members (properties and methods) of the $userGroupArray variable
$userGroupArray | Get-Member

# Loop again through each user
for($i=0; $i -lt $neededUsers; $i++){
    # For each group DN in the current user's entry in $userGroupArray
    foreach ($dn in $userGroupArray[$i]) {
        # Print the corresponding group name from the $groups hashtable
        Write-Host ("- {0}" -f $groups[$dn])        
>>>>>>> Stashed changes
    }
}
