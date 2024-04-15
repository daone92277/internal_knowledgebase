function Copy-FilesToBlob {
    param(
        [string]$FileShareUrl,
        [string]$BlobContainerUrl,
        [string]$SourceSasToken,
        [string]$DestinationSasToken
    )

    $AzCopyCommand = "azcopy cp `"$FileShareUrl$SourceSasToken`" `"$BlobContainerUrl$DestinationSasToken`" --recursive=true --overwrite=false"

    try {
        Invoke-Expression $AzCopyCommand
        Write-Verbose "AzCopy completed successfully."
    } catch {
        Write-Error "AzCopy failed: $($_.Exception.Message)" 
    }
}

function Remove-FilesFromShare {
    param(
        [string]$FileShareUrl,
        [string]$SasToken
    )

    # Extract the storage account name from the URL
    $storageAccountName = ($FileShareUrl -split "\.")[0].Split("//")[-1]

    # Create a storage context
    $context = New-AzureStorageContext -StorageAccountName $storageAccountName -SasToken $SasToken

    # Extract the share name from the URL
    $shareName = $FileShareUrl.Split("/")[-1]

    # Get the file share
    $share = Get-AzureStorageShare -Name $shareName -Context $context

    # Recursive delete function
    $deleteFilesRecursively = {
        param($dir)

        # Get all subdirectories first
        $subDirs = Get-AzureStorageFile -Share $share.Name -Path $dir -Context $context | Where-Object { $_.GetType().Name -eq "AzureStorageDirectory" }

        # Recursively delete files in subdirectories
        foreach ($subDir in $subDirs) {
            & $deleteFilesRecursively $subDir.Name
        }

        # Delete files in the current directory
        Get-AzureStorageFile -Share $share.Name -Path $dir -Context $context | Where-Object { $_.GetType().Name -eq "AzureStorageFile" } | Remove-AzureStorageFile -Force -Context $context

        Write-Verbose "Files deleted from directory: $dir"
    }

    # Start the deletion from the root of the share
    & $deleteFilesRecursively ""
}

# Set your variables (Make sure to update these with the correct values)
$FileShareUrl   = "https://uedev28file02.file.core.windows.net/dev87"
$BlobContainerUrl = "https://uedev28file01.blob.core.windows.net/systemtest4/DbLogs"
$SourceSasToken  = "..." 
$DestinationSasToken = "..."

# Execute the copy
Copy-FilesToBlob $FileShareUrl $BlobContainerUrl $SourceSasToken $DestinationSasToken 

# Delete files from the share
Remove-FilesFromShare $FileShareUrl $SourceSasToken

pause
