# specify directories to watch
$nas_dir = "Z:\\Collections\\Prod\\Outbound"
$afs_dir = "https://ueprd28file01.file.core.windows.net/prd/NewCo/Logs"

# specify email details
$smtp_server = "higmx.thehartford.com"
$from = "David.greene@thehartford.com"
$to = "david.greene@thehartford.com", "carlos.aponte@thehartford.com"

# initialize email body
$emailBody = ""

try {
    # check for new files in NAS directory
    $today = Get-Date
    $latest = Get-ChildItem -Path $nas_dir -Recurse | Where-Object {!$_.PSIsContainer} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest.LastWriteTime.Date -ne $today.Date) {
        $emailBody += "No new file has been added today in NAS location \\Collections\\Prod\\Outbound: " + $nas_dir + "`n"
    }

    # Install Azure.Storage module if not already installed
    if (-not (Get-Module -ListAvailable -Name Azure.Storage)) {
        Install-Module -Name Azure.Storage -Scope CurrentUser -Force -AllowClobber -Confirm:$false
    }
    
    # Import Azure.Storage module
    Import-Module Azure.Storage

    # authenticate with Azure
    $context = New-AzureStorageContext -StorageAccountName "ueprd28file01" -SasToken "sv=2021-10-04&ss=bf&srt=sco&st=2024-06-28T05%3A00%3A00Z&se=2026-07-01T05%3A00%3A00Z&sp=rwlac&sig=ANOOt1gEMFi%2FK3uPlhwodIEwJlgtaDejJIkQvxFytc4%3D"

    # check for job failures in AFS log files
    $files = Get-AzureStorageFile -Context $context -ShareName "prd" -Path "NewCo/Logs" -Recurse
    foreach ($file in $files) {
        if ($file -is [Microsoft.WindowsAzure.Storage.File.CloudFile]) {
            $content = Get-AzureStorageFileContent -Context $context -ShareName "prd" -Path $file.Name | Out-String
            if ($content -match "job failed" -or $content -match "job failure") {
                $emailBody += "A job failure has been detected in the log file: " + $file.Name + "`n"
            }
        }
    }

    # send email if there were any issues
    if ($emailBody -ne "") {
        $subject = "Alert: Job Failure or Missing File Detected"
        Send-MailMessage -From $from -To $to -Subject $subject -Body $emailBody -SmtpServer $smtp_server
    }
} catch {
    Write-Host $_.Exception.Message
}

pause
