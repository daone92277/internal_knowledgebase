$AzCopyPath = "C:\AzCopy\azcopy.exe"
$logFile = "C:\AzCopy\MoveExtendedMessagesToBlob_output.txt"

function Copy-FilesToBlob {
    param(
        [string]$FileShareUrl,
        [string]$BlobContainerUrl,
        [string]$SourceSasToken,
        [string]$DestinationSasToken
    )

    $AzCopyCommand = "$AzCopyPath cp `"$FileShareUrl$SourceSasToken`" `"$BlobContainerUrl$DestinationSasToken`" --recursive=true --overwrite=false > $logFile"

    try {
        Invoke-Expression $AzCopyCommand
    } catch {
        Add-Content -Value "AzCopy failed: $($_.Exception.Message)" -Path $logFile
    }
}

function Delete-FilesFromShare {
    param(
        [string]$FileShareUrl,
        [string]$SourceSasToken
    )

    $AzCopyCommand = "$AzCopyPath rm `"$FileShareUrl/*$SourceSasToken`" --recursive=true > $logFile"

    try {
        Invoke-Expression $AzCopyCommand
    } catch {
        Add-Content -Value "AzCopy delete failed: $($_.Exception.Message)" -Path $logFile
    }
}

$FileShareUrl = "https://uedev28file02.file.core.windows.net/dev90/Logs/ExtendedLoggingMessages"
$BlobContainerUrl = "https://ueuat28file01.blob.core.windows.net/newcobillinglogs"
$SourceSasToken = "?sv=2023-08-03&ss=bf&srt=sco&st=2024-07-03T05%3A00%3A00Z&se=2026-07-01T05%3A00%3A00Z&sp=rwdlacf&sig=fFuZ%2FDjtUITFZXr22V%2Bhw%2Bt6YqoTFmvgNo1sgV2a%2BnU%3D"
$DestinationSasToken = "?sv=2020-04-08&ss=bf&srt=sco&st=2024-06-28T05%3A00%3A00Z&se=2026-07-01T05%3A00%3A00Z&sp=rwdlacf&sig=z%2FUcqheey7s6agchA5OYnDrq%2BuCOKJ4WtXK6%2FC4dpek%3D"

Copy-FilesToBlob $FileShareUrl $BlobContainerUrl $SourceSasToken $DestinationSasToken 
Delete-FilesFromShare $FileShareUrl $SourceSasToken

$azCopyOutput = Get-Content -Path $logFile -Raw

$today = Get-Date -Format "MM-dd-yyyy"
$subject = "MoveExtendedMessagesToBlob $today"

Send-MailMessage -From "David.greene@thehartford.com" -To "david.greene@thehartford.com", "carlos.aponte@thehartford.com" -Subject $subject -Body $azCopyOutput -Attachments $logFile -SmtpServer "higmx.thehartford.com"

pause