# Define variables (You might need to adjust these based on your folder structure)
$containerUrl = "https://uedev28file01.blob.core.windows.net/systemtest4-uedev28app87/"
$mainFolder = "billingLogs" # The main folder containing other folders
$sasToken = "?sv=2022-11-02&ss=bf&srt=sco&sp=rwdlaciytfx&se=2024-07-02T04:44:17Z&st=2024-03-13T20:44:17Z&spr=https&sig=03UTZZVFIZ8wXpBVruzSkfhBzmlpaTm8uuf%2BOdQDbLg%3D"
$logfile = "deletion_log.txt"  

# Enhanced date handling
$dateThreshold = Get-Date -Format "yyyyMMdd" 
$datePrefix = $dateThreshold + "_" 

# Get a storage context
$ctx = New-AzStorageContext -StorageAccountName "uedev28file01" -SasToken $sasToken

# Display the container name
Write-Host "Scanning container: systemtest4-uedev28app87/$mainFolder"

# List blobs, filter by date prefix
$blobs = Get-AzStorageBlob -Container "systemtest4-uedev28app87" -Context $ctx | 
   Where-Object { 
    $_.Name.StartsWith($mainFolder + "/") -and  
    $_.Name.StartsWith($datePrefix) -and
    $_.Name.EndsWith(".log") 
   } 

# Loop through blobs with error handling and logging
foreach ($blob in $blobs) {
  Write-Host "Blob Name:" $blob.Name
  Write-Host "Date Prefix:" $datePrefix 

 $blobUrl = $containerUrl + "/" + $blob.Name + $sasToken

 try {
  & azcopy rm $blobUrl >> $logfile 
  Write-Host "Deleted blob: $($blob.Name)" 
 } catch {
  Write-Error "Error deleting blob: $($blob.Name) - $($_.Exception.Message)" 
  Write-Error $_.Exception >> $logfile  
 }
}

$env:AZCOPY_CONCURRENCY_VALUE = "AUTO";
$env:AZCOPY_CRED_TYPE = "Anonymous";
./azcopy.exe remove "https://uedev28file01.blob.core.windows.net/systemtest4-uedev28app87/billingLogs/Logs/BRCCLogs/20231228_BRCC_Trace.log?sv=2022-11-02&ss=bf&srt=sco&sp=rwdlaciytfx&se=2024-07-02T04%3A44%3A17Z&st=2024-03-13T20%3A44%3A17Z&spr=https&sig=03UTZZVFIZ8wXpBVruzSkfhBzmlpaTm8uuf%2BOdQDbLg%3D" --from-to=BlobTrash --recursive --log-level=INFO;
$env:AZCOPY_CONCURRENCY_VALUE = "";
$env:AZCOPY_CRED_TYPE = "";

