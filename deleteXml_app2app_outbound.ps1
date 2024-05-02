# ========= Preparation =========

# Import the module for working with Azure Storage
Import-Module Az.Storage

# Define your variables
$storageAccountName = "uedev28file02"
$shareName = "dev87"
$targetFolder = "APP2APP/SystemTest4/Outbound/Archive"
$sasToken = "?sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2024-07-02T04%3A03%3A10Z&st=2024-03-19T20%3A03%3A10Z&spr=https&sig=EJfN%2Br9ZVNGIlYSsemYnEsSCxGfCMtI%2BtOVjHeLxOns%3D"

# Retention period (in days)
$retentionPeriod = 30

# ========= Core Logic =========

# Calculate the cutoff date
$cutoffDate = (Get-Date).AddDays(-$retentionPeriod)

# Create a storage context (connect to your Azure File share)
$context = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken

# Check if the target folder exists
$folderExists = $false
try {
    Get-AzStorageFile -Context $context -ShareName $shareName -Path $targetFolder -ErrorAction Stop | Out-Null
    $folderExists = $true
} catch {
    # Error indicates the folder likely doesn't exist 
}

if ($folderExists) {
    # Get files in the target folder and iterate through them
    Get-AzStorageFile -Context $context -ShareName $shareName -Path $targetFolder | ForEach-Object {
        # Debug: Display the file path being processed
        Write-Host "Processing file: $($_.Path); Creation Time: $($_.Properties.CreationTime)"

        # Check and delete if the file is older than the cutoff date
        if ($_.Properties.CreationTime -lt $cutoffDate) {
            Remove-AzStorageFile -Context $context -ShareName $shareName -Path $_.Path -Force
        }
    }

    # ========= (Optional) Verbose Output =========
    Write-Host "Files older than $cutoffDate in the Azure File share have been permanently deleted."
} else {
    Write-Warning "Target folder '$targetFolder' not found in the file share."
}

pause

<# Processing file: ; Creation Time:
Remove-AzStorageFile: C:\Users\DG04170\OneDrive - The Hartford\Desktop\pythonScripts\POWERSHELL\afsDelete_nonbilling\deleteXml_app2app_outbound.ps1:40
Line |
  40 |  … rageFile -Context $context -ShareName $shareName -Path $_.Path -Force
     |                                                           ~~~~~~~
     | Cannot validate argument on parameter 'Path'. The argument is null or empty. Provide an argument that is not
     | null or empty, and then try the command again.
Files older than 04/02/2024 11:27:11 in the Azure File share have been permanently deleted.
Press Enter to continue...:
 #>
