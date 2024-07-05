# specify directories to watch
$nas_dir = "Z:\\Collections\\Prod\\Outbound"
$afs_dir = "NewCo/Logs"

# specify email details
$smtp_server = "higmx.thehartford.com"
$from = "David.greene@thehartford.com"
$to = "david.greene@thehartford.com", "carlos.aponte@thehartford.com"

# initialize email body
$emailBody = ""

# Function to recursively get all files in a directory
function Get-AllFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string] $ShareName,
        [string] $Path
    )
    
    $files = @()

    $items = Get-AzureStorageFile -Context $context -ShareName $ShareName -Path $Path
    foreach ($item in $items) {
        if ($item -is [Microsoft.WindowsAzure.Storage.File.CloudFile]) {
            $files += ,$item
        } elseif ($item -is [Microsoft.WindowsAzure.Storage.File.CloudFileDirectory]) {
            $files += Get-AllFiles -ShareName $ShareName -Path $item.Prefix
        }
    }

    return $files
}

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

    # Get all files recursively from the root directory
    $files = Get-AllFiles -ShareName "prd" -Path $afs_dir

    # check for job failures in AFS log files
    foreach ($file in $files) {
        $content = Get-AzureStorageFileContent -Context $context -ShareName "prd" -Path $file.Prefix | Out-String
        if ($content -match "job failed" -or $content -match "job failure") {
            $emailBody += "A job failure has been detected in the log file: " + $file.Prefix + "`n"
        }
    }

    # send email if there were any issues
    if ($emailBody -ne "") {
        $subject = "Alert: Job Failure or Missing File Detected"
        Send-MailMessage -From $from -To $to -Subject $subject -Body $emailBody -SmtpServer $smtp_server
    }
} catch {
    Write-Host "An error occurred: $_.Exception.Message"
}

pause
