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

    $context = New-AzStorageContext -StorageAccountName "uedev28file02" -SasToken $SasToken
    $shareName = $FileShareUrl.Split("/")[-1]
    $share = Get-AzStorageShare -Name $shareName -Context $context

    # Define a script block for recursive deletion
    $deleteFilesRecursively = {
        param($dir)

        try {
            # Get all files in the current directory and delete them
            Get-AzStorageFile -Share $share -Path $dir | Remove-AzStorageFile
            Write-Verbose "Files deleted from directory: $dir"
        } catch {
            Write-Error "Failed to delete files from directory: $dir - Error: $($_.Exception.Message)"
        }

        # Get all subdirectories in the current directory
        $subDirs = Get-AzStorageDirectory -Share $share -Path $dir

        # Recursively delete files in the subdirectories
        foreach ($subDir in $subDirs) {
            & $deleteFilesRecursively $subDir.Name
        }
    }

    # Start the recursive deletion from the root directory
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
