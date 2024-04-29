# ***** ADJUST THESE VALUES FOR YOUR ENVIRONMENT *****
$storageAccountName = "uedev28file02"
$shareName = "dev87"
$targetFolder = "APP2APP/SystemTest4/Outbound/Archive"
$sasToken = "?sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2024-07-02T04%3A03%3A10Z&st=2024-03-19T20%3A03%3A10Z&spr=https&sig=EJfN%2Br9ZVNGIlYSsemYnEsSCxGfCMtI%2BtOVjHeLxOns%3D"

# Calculate the cutoff date (1 day prior to today)
$cutoffDate = (Get-Date).AddDays(-1).Date

# Authenticate with Azure Storage
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken

# Get files from the Azure File Share, ensuring only files are listed
$files = Get-AzStorageFile -ShareName $shareName -Context $ctx -Path $targetFolder | Where-Object { -not $_.IsDirectory }

# Filter and remove files older than 1 day based on the timestamp in the filename
foreach ($file in $files) {
    try {
        # Only process files that are not directories
        if (-not $file.IsDirectory) {
            # Extract date from the filename assuming the format is "<prefix>_AppToAppFeed_MM-dd-yyyy_<suffix>.xml"
            $fileComponents = $file.Name -split '_'
            $datePart = $fileComponents[3]
            $fileDate = [datetime]::ParseExact($datePart, "MM-dd-yyyy", $null)
            
            # Compare the extracted date to the cutoff date
            if ($fileDate -lt $cutoffDate) {
                # Construct the URI for the file
                $fileUri = "https://$storageAccountName.file.core.windows.net/$shareName/$($file.CloudPath)"
                
                # Command to remove the file using azcopy
                $azCopyCommand = "azcopy remove `"$fileUri`" --recursive=true --sas-token `"$sasToken`""
                
                # Execute the removal command
                Invoke-Expression $azCopyCommand
            }
        }
    } catch [System.Management.Automation.MethodInvocationException] {
        Write-Warning "Failed to delete file: $($file.Name)"
    } catch [System.FormatException] {
        Write-Warning "Date parsing failed for file: $($file.Name) with date part: $datePart"
    } catch {
        Write-Warning "An unknown error occurred with file: $($file.Name)"
    }
}

pause


url : https://uedev28file02.file.core.windows.net/dev87/APP2APP/SystemTest4/Outbound/Archive/638493942218567792_Feedback_AppToAppFeed_04-22-2024_12820.xml
path : APP2APP/SystemTest4/Outbound/Archive/638493942218567792_Feedback_AppToAppFeed_04-22-2024_12820.xml

638490461205082995_AppToAppFeed_04-18-2024_12724.xml
638490486856700998_AppToAppFeed_04-18-2024_12725.xml
638490522428709041_AppToAppFeed_04-18-2024_12726.xml
638490559948810235_AppToAppFeed_04-18-2024_12727.xml
