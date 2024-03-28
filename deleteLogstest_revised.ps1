# Define variables
$containerUrl = "https://uedev28file01.blob.core.windows.net/systemtest4-uedev28app87"
$mainFolder = "billingLogs/Logs/" # Include the base Logs folder
$sasToken = "?sv=2022-11-02&ss=bf&srt=sco&sp=rwdlaciytfx&se=2024-07-02T04:44:17Z&st=2024-03-13T20:44:17Z&spr=https&sig=03UTZZVFIZ8wXpBVruzSkfhBzmlpaTm8uuf+OdQDbLg="
$logfile = "deletion_log.txt"

# Ensure the logfile is created or cleared for new logs
"" | Out-File $logfile

# Authenticate with Azure Storage
$ctx = New-AzStorageContext -StorageAccountName "uedev28file01" -SasToken $sasToken

try {
    # Get files directly within subfolders 
    $subFolders = Get-AzStorageBlob -Container "systemtest4-uedev28app87" -Prefix $mainFolder -Context $ctx | 
                  Where-Object { !$_.ICloudBlob.IsPrefix } | 
                  Select-Object -ExpandProperty Name | 
                  Get-Unique  # Ensure unique folder names

    foreach ($subFolder in $subFolders) {
        $folderPath = $subFolder.Substring($mainFolder.Length)  # Remove prefix

        # Display the subfolder being scanned
        Write-Host "Scanning container: systemtest4-uedev28app87/$folderPath for logs older than 30 days..."

        $blobs = Get-AzStorageFile -Container "systemtest4-uedev28app87" -Path $folderPath -Context $ctx | 
                 Where-Object { $_.Name -match "\d{8}_" -and $_.Name -like "*.log" } 

        # ... (Rest of your blob processing logic) ...
    }
} catch {
    Write-Host "An error occurred: $_" | Out-File $logfile -Append
}

Write-Host "Deletion process complete."
