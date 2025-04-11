function YorN_Query {
    param(
        [string]$text  # The prompt text that will be displayed to the user
    )

    do {
        # Prompt the user with the given text followed by "y/n"
        $answer = Read-Host($text + ' y/n')

        if ($answer -match 'y') {
            # If the input matches 'y', return $true
            return $true
        } elseif ($answer -match 'n') {
            # If the input matches 'n', return $false
            return $false
        } else {
            # If the input is neither, print an error message
            Write-Host ('Invalid input')
        }

    } while ($answer -ne 'y' -and $answer -ne 'n')  # Repeat until a valid answer is given
}