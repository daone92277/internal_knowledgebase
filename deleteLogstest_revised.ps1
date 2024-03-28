function Delete-OldBlobs {
  param(
    [string]$BlobContainerUrl,
    [string]$SasToken,
    [string]$MainFolder,
    [int]$DaysOld
  )

  # Calculate the date threshold
  $dateThreshold = (Get-Date).AddDays(-$DaysOld).ToString("yyyyMMdd")

  # Set environment variables
  $env:AZCOPY_CONCURRENCY_VALUE = "AUTO"
  $env:AZCOPY_CRED_TYPE = "Anonymous"

  # Get the storage account and container names from the URL
  $storageAccountName = $BlobContainerUrl.Split('/')[2].Split('.')[0]
  $containerName = $BlobContainerUrl.Split('/')[3]

  # Create a storage context
  $context = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $SasToken

  # List blobs in the container
  $blobs = Get-AzStorageBlob -Container $containerName -Context $context

  # Filter blobs based on the date threshold and delete each one
  foreach ($blob in $blobs) {
    if ($blob.Name -like "*$dateThreshold*.log") {
      $AzCopyCommand = "azcopy.exe remove `"$BlobContainerUrl/$MainFolder/$($blob.Name)$SasToken`" --from-to=BlobTrash --log-level=INFO >> deletion_log.txt"
      Invoke-Expression $AzCopyCommand
        Write-Host "Deleted blob: $($blob.Name)" # Output deletion message
    }
  }

  # Reset environment variables
  $env:AZCOPY_CONCURRENCY_VALUE = ""
  $env:AZCOPY_CRED_TYPE = ""
}

# Set your variables
$BlobContainerUrl = "https://uedev28file01.blob.core.windows.net/systemtest4-uedev28app87/billingLogs/Logs"
$SasToken = "?sv=2022-11-02&ss=bf&srt=sco&sp=rwdlaciytfx&se=2024-07-02T04%3A44%3A17Z&st=2024-03-13T20%3A44%3A17Z&spr=https&sig=03UTZZVFIZ8wXpBVruzSkfhBzmlpaTm8uuf%2BOdQDbLg%3D"
$DaysOld = 30

# Execute the delete
Delete-OldBlobs $BlobContainerUrl $SasToken $DaysOld

pause 
