
# Define variables
$containerUrl = "https://uedev28file01.blob.core.windows.net/systemtest4-uedev28app87"
$mainFolder = "billingLogs" # The main folder containing other folders
$sasToken = "?sv=2022-11-02&ss=bf&srt=sco&sp=rwdlaciytfx&se=2024-07-02T04:44:17Z&st=2024-03-13T20:44:17Z&spr=https&sig=03UTZZVFIZ8wXpBVruzSkfhBzmlpaTm8uuf+OdQDbLg="
$logfile = "deletion_log.txt"

# Ensure the logfile is created or cleared for new logs
"" | Out-File $logfile

# Get the current date minus 30 days in "yyyyMMdd" format
$dateThreshold = (Get-Date).AddDays(-30).ToString("yyyyMMdd")

# Display the scanning target information
Write-Host "Scanning container: systemtest4-uedev28app87/$mainFolder for logs older than 30 days"

# Authenticate with Azure Storage
$ctx = New-AzStorageContext -StorageAccountName "uedev28file01" -SasToken $sasToken

# List and filter blobs based on the prefix and date
$blobs = Get-AzStorageBlob -Container "systemtest4-uedev28app87" -Context $ctx | Where-Object {
    $_.Name -match "^$mainFolder/\d{8}_" -and $_.Name -like "*.log"
}

foreach ($blob in $blobs) {
    # Extract the date part of the blob name to compare with the threshold
    $blobDatePrefix = $blob.Name.Split('/')[1].Substring(0, 8)
    if ([int]$blobDatePrefix -le [int]$dateThreshold) {
        $blobUrl = "$containerUrl/$($blob.Name)$sasToken"
        try {
            # Execute AzCopy command to delete the blob
            & azcopy remove "$blobUrl" --log-level=ERROR | Out-File $logfile -Append
            Write-Host "Deleted blob: $($blob.Name)" | Out-File $logfile -Append  
        } catch {
            Write-Error "Error deleting blob: $($blob.Name) - $($_.Exception.Message)" 
            "Error deleting blob: $($blob.Name) - $($_.Exception.Message)" | Out-File $logfile -Append
        }
    }
}

Write-Host "Deletion process complete."
