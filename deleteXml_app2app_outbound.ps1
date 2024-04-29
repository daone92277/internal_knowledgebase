<# 
# ***** ADJUST THESE VALUES FOR YOUR ENVIRONMENT *****
$storageAccountName = "uedev28file02"
$shareName = "dev87"
$targetFolder = "APP2APP/SystemTest4/Outbound/Archive"
$sasToken = "?sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2024-07-02T04%3A03%3A10Z&st=2024-03-19T20%3A03%3A10Z&spr=https&sig=EJfN%2Br9ZVNGIlYSsemYnEsSCxGfCMtI%2BtOVjHeLxOns%3D"
# Calculate the cutoff date (30 days prior to today)
$cutoffDate = (Get-Date).AddDays(-1).Date


# Construct the base AzCopy command
$baseAzCopyCommand = "azcopy remove"

# Authenticate with Azure Storage
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken

# Get files from the Azure File Share (no changes here)
$files = Get-AzStorageFile -ShareName $shareName -Context $ctx -Path $targetFolder

$files | Where-Object {
  $_.LastWriteTime -lt $cutoffDate
} | ForEach-Object {
  $azCopyCommand = $baseAzCopyCommand + " 'https://$storageAccountName.file.core.windows.net/$shareName/$targetFolder?$sasToken'"
  
  
  # Use 'azcopy remove' directly for deletion
  Invoke-Expression $azCopyCommand 
}

pause #>

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
$files = Get-AzStorageFile -ShareName $shareName -Context $ctx -Path $targetFolder

# Filter and remove files older than 1 day based on the timestamp in the filename
foreach ($file in $files) {
    # Extract the date portion from the filename (assuming the format is consistent)
    $dateString = $file.Name -split "_AppToAppFeed_"
    $fileDate = [datetime]::ParseExact($dateString[1], "MM-dd-yyyy", $null)
    
    # Compare the extracted date to the cutoff date
    if ($fileDate -lt $cutoffDate) {
        # Construct the full file path
        $filePath = Join-Path -Path $file.DirectoryPath -ChildPath $file.Name
        
        # Remove the file (you can remove the -WhatIf switch to actually delete the files)
        Remove-AzStorageFile -ShareName $shareName -Path $filePath -Context $ctx -WhatIf
    }
}


pause