# ***** ADJUST THESE VALUES FOR YOUR ENVIRONMENT *****
$storageAccountName = "uedev28file02"
$shareName = "dev87"
$targetFolder = "APP2APP/SystemTest4/Outbound/Archive"
$sasToken = "?sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2024-07-02T04%3A03%3A10Z&st=2024-03-19T20%3A03%3A10Z&spr=https&sig=EJfN%2Br9ZVNGIlYSsemYnEsSCxGfCMtI%2BtOVjHeLxOns%3D"

# Calculate the cutoff date (1 day prior to today)
$cutoffDate = (Get-Date).AddDays(-1).Date

# Authenticate with Azure Storage
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken

# Get files from the Azure File Share
$files = Get-AzStorageFile -ShareName $shareName -Context $ctx -Path $targetFolder | Where-Object { $_.GetType().Name -eq "CloudFile" }

# Filter and remove files older than 1 day based on the timestamp in the filename
foreach ($file in $files) {
    try {
        # Attempt to extract the date portion from the filename
        $dateString = $file.Name -split "_AppToAppFeed_"
        if ($dateString.Length -lt 2) {
            Write-Warning "Filename format unexpected for file: $($file.Name)"
            continue
        }
        $datePortion = ($dateString[1] -split "_")[0]
        $fileDate = [datetime]::ParseExact($datePortion, "MM-dd-yyyy", $null)
        
        # Compare the extracted date to the cutoff date
        if ($fileDate -lt $cutoffDate) {
            # Construct the full file path
            $filePath = Join-Path -Path $file.DirectoryPath -ChildPath $file.Name
            
            # Remove the file (remove the -WhatIf switch to actually delete the files)
            Remove-AzStorageFile -ShareName $shareName -Path $filePath -Context $ctx -WhatIf
        }
    } catch [System.Management.Automation.MethodInvocationException] {
        Write-Warning "Failed to delete file: $($file.Name)"
    } catch [System.FormatException] {
        Write-Warning "Date parsing failed for file: $($file.Name) with date part: $datePortion"
    } catch {
        Write-Warning "An unknown error occurred with file: $($file.Name)"
    }
}

pause



638490461205082995_AppToAppFeed_04-18-2024_12724.xml
638490486856700998_AppToAppFeed_04-18-2024_12725.xml
638490522428709041_AppToAppFeed_04-18-2024_12726.xml
638490559948810235_AppToAppFeed_04-18-2024_12727.xml
