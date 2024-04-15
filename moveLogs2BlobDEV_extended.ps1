function Copy-FilesToBlob {
    param(
        [string]$FileShareUrl,
        [string]$BlobContainerUrl,
        [string]$SourceSasToken,
        [string]$DestinationSasToken
    )

    $AzCopyCommand = "azcopy cp `"$FileShareUrl$SourceSasToken`" `"$BlobContainerUrl$DestinationSasToken`" --recursive=true --overwrite=false"
    Invoke-Expression $AzCopyCommand
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

    # Get all files in the current directory and delete them
    Get-AzStorageFile -Share $share -Path $dir | Remove-AzStorageFile

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

# Set your variables
$FileShareUrl      = "https://uedev28file02.file.core.windows.net/dev87"
$BlobContainerUrl  = "https://uedev28file01.blob.core.windows.net/systemtest4/DbLogs"
$SourceSasToken    = "?sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2024-07-02T04:03:10Z&st=2024-03-19T20:03:10Z&spr=https&sig=EJfN%2Br9ZVNGIlYSsemYnEsSCxGfCMtI%2BtOVjHeLxOns%3D"
$DestinationSasToken = "?sv=2022-11-02&ss=bf&srt=sco&sp=rwdlaciytfx&se=2024-07-02T04:44:17Z&st=2024-03-13T20:44:17Z&spr=https&sig=03UTZZVFIZ8wXpBVruzSkfhBzmlpaTm8uuf%2BOdQDbLg%3D"

# Execute the copy
Copy-FilesToBlob $FileShareUrl $BlobContainerUrl $SourceSasToken $DestinationSasToken 

# Delete files from the share
Remove-FilesFromShare $FileShareUrl $SourceSasToken

pause


