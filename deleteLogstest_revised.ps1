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
    # Get subfolders within the Logs folder
    $subFolders = Get-AzStorageDirectory -Prefix $mainFolder -Context $ctx | 
                  Where-Object { $_.IsDirectory } |
                  Select-Object -ExpandProperty Name 

    foreach ($subFolder in $subFolders) {
        $folderPath = $subFolder.Substring($mainFolder.Length)  # Remove prefix

        # Display the subfolder being scanned
        Write-Host "Scanning container: systemtest4-uedev28app87/$folderPath for logs older than 30 days..."

        $blobs = Get-AzStorageBlob -Container "systemtest4-uedev28app87" -Context $ctx | Where-Object {
            $_.Name -match "^$folderPath/\d{8}_" -and $_.Name -like "*.log"
        }

        $blobCount = ($blobs | Measure-Object).Count
        Write-Host "$blobCount blobs found in the target folder."

        foreach ($blob in $blobs) {
            $blobDatePrefix = $blob.Name.Split('/')[1].Substring(0, 8)
            $dateThreshold = (Get-Date).AddDays(-30).ToString("yyyyMMdd")

            if ([int]$blobDatePrefix -le [int]$dateThreshold) {
                $blobUrl = "$containerUrl/$($blob.Name)$sasToken"
                Write-Host "Attempting to delete: $($blob.Name)"

                try {
                    & azcopy remove "$blobUrl" --log-level=ERROR
                    Write-Host "Successfully deleted: $($blob.Name)" | Out-File $logfile -Append
                } catch {
                    Write-Host "Failed to delete: $($blob.Name)" | Out-File $logfile -Append
                }
            }
        }
    }
} catch {
    Write-Host "An error occurred: $_" | Out-File $logfile -Append
}

Write-Host "Deletion process complete."
