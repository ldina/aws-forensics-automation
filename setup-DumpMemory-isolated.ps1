<#
setup-DumpMemory-isolated.ps1 v1.0
https://github.com/ldina
Author: Lorenzo Dina - ldina - @joecondo

Function: This script will 
- download Magnet Ram Capture, WinPmem, AWS CLI from internet to your AWS S3 bucket
Prerequisites:
- AWS CloudShell in powershell mode (pwsh)
- Internet connection to download the files
- An S3 Bucket accessible by AWS CloudShell 
- Updated URL references for tool download

v1.0 - "Initial Release"
#>


# S3 bucket name for binaries download
$MyS3BucketInstaller = "afa-installer"
#AWS CLI download URL
$AwsCliURL = "https://awscli.amazonaws.com/AWSCLIV2.msi"
# Magnet Ram capture download URL
$MagnetURL = "https://storage.googleapis.com/mfi-files/free_tools/MagnetRAMCapture/MRCv120.exe"
# WinPmem download URL
$WinPmemURL = "https://github.com/Velocidex/WinPmem/releases/download/v4.0.rc1/winpmem_mini_x64_rc2.exe"

# Binaries download
Write-Host -Fore Cyan "Downloading binaries to CloudShell"
curl $AwsCliURL --output AWSCLIV2.msi
curl $MagnetURL --output magnet.exe
curl $WinPmemURL --output winpmem.exe

# Copying  downloaded binaries to an S3 bucket
Write-Host -Fore Cyan "Uploading binaries to the S3 bucket"
aws s3 cp /home/cloudshell-user/magnet.exe s3://$MyS3BucketInstaller --no-progress
aws s3 cp /home/cloudshell-user/winpmem.exe s3://$MyS3BucketInstaller --no-progress
