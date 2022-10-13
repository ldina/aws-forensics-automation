<#
ec2-win-DumpMemory-isolated.ps1 v1.0
https://github.com/ldina
Author: Lorenzo Dina - ldina - @joecondo
Function: This script will 
- download Magnet Ram Capture, WinPmem, AWS CLI from a preconfigured AWS S3 bucket to your AWS EC2 instance
- capture a memory image with Magnet Ram Capture and WinPmem
- hash the captured dump files
- capture OS build info
- transfer the artifacts back to an AWS S3 bucket
Prerequisites:
- An S3 Bucket pre-configured with binaries of the tool to be downloaded
- An S3 Bucket accessible by the EC2 instance for artificats upload
- OPTIONAL: if you run the script via AWS SSM the EC2 instance must have assigned an IAM role that includes SSM support

v1.0 - "Initial Release"
credits to @dwmetz https://github.com/dwmetz/ where I got inspirations and code snippets to improve and complete my code
#>


#Initizializing the variables
$MyMemDumpInstanceId =""
$MyMemDumpInstanceIdTimeStamped =""
$MyMemDumpInstanceIdTimeStamped1 =""
$MyMemDumpInstanceIdTimeStamped2 =""

# Set-AWSCredentials –AccessKey 'AccessKeyId' –SecretKey 'SecretAccessKey'
Set-DefaultAWSRegion -Region eu-west-1

# Getting InstanceId for proper filename handling
$MyMemDumpInstanceId = Get-EC2InstanceMetadata -Category InstanceId

# S3 bucket name for binaries download
$MyS3BucketInstaller = "afa-installer"

# Destination S3 bucket name
$MyS3Bucket = 'localec2dump'

#AWS CLI download URL
$AwsCliURL = "https://awscli.amazonaws.com/AWSCLIV2.msi"

# Magnet Ram capture download URL
$MagnetURL = "https://storage.googleapis.com/mfi-files/free_tools/MagnetRAMCapture/MRCv120.exe"

# WinPmem download URL
$WinPmemURL = "https://github.com/Velocidex/WinPmem/releases/download/v4.0.rc1/winpmem_mini_x64_rc2.exe"

# Installing AWS CLI
Write-Host -Fore Cyan "Installing AWS CLI"
msiexec.exe /i $AwsCliURL /q

# Installing Magnet RAM Capture
Write-Host -Fore Cyan "Installing Magnet RAM Capture"
cd  C:\Windows\Temp\
.\aws.exe s3 cp s3://$MyS3BucketInstaller/magnet.exe C:\Windows\Temp\  --no-progress
#curl $MagnetURL -outfile magnet.exe

# Installing WinPmem Memory Dumper
Write-Host -Fore Cyan "Installing WinPmem Memory Dumper"
.\aws.exe s3 cp s3://$MyS3BucketInstaller/winpmem.exe C:\Windows\Temp\  --no-progress
 
# Composing a timestamped name for the memdump (newbie way)
$MyDate = Get-Date -Format "yyyyMMdd"
$MyTime = Get-Date -Format "HHmmss"
$MyTimeStamp = $MyDate
$MyTimeStamp += 'T'
$MyTimeStamp += $MyTime
$MyMemDumpInstanceIdTimeStamped = $MyTimeStamp
$MyMemDumpInstanceIdTimeStamped += '_'
$MyMemDumpInstanceIdTimeStamped += $MyMemDumpInstanceId

# Executing WinPmem Memory Dumper
$MyMemDumpInstanceIdTimeStamped1 = $MyMemDumpInstanceIdTimeStamped
$MyMemDumpInstanceIdTimeStamped1 += '_winpmem.raw'
Write-Host -Fore Cyan "Dumping RAM method 1"
.\winpmem.exe $MyMemDumpInstanceIdTimeStamped1

# Executing Magnet RAM Capture
$MyMemDumpInstanceIdTimeStamped2 = $MyMemDumpInstanceIdTimeStamped
$MyMemDumpInstanceIdTimeStamped2 += '_magnetram.raw'
Write-Host -Fore Cyan "Dumping RAM method 2"
.\magnet.exe /accepteula /silent /go "C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped2"

# Sleeping while Magnet RAM Capture the ram to prevent that the S3 process start before the dumping is finished. It may require adjuste the value for large RAM instances
Write-Host -Fore Cyan "Sleeping while Magnet RAM Capture"
Start-Sleep -Seconds 5
Write-Host -Fore Cyan "Waiting for capture to complete..."
Wait-Process -name "magnet"

# Documenting the OS build information
Write-Host -Fore Cyan "Determining OS build info..."
$MyMemDumpOSVersion = $MyMemDumpInstanceIdTimeStamped
$MyMemDumpOSVersion += '_osversion.txt'
[System.Environment]::OSVersion.Version > $MyMemDumpOSVersion

#Hashing dumped memory files
Write-Host -Fore Cyan "Hashing"
$MyMemDumpHash = $MyMemDumpInstanceIdTimeStamped
$MyMemDumpHash += '_hash.txt'
Get-FileHash C:\Windows\Temp\*.raw -Algorithm SHA1 | Format-List >$MyMemDumpHash
 
# Copying instance artifact to an S3 bucket  where the EC2 has a role access
Write-Host -Fore Cyan "Uploading memory dumps and artifacts to S3 bucket"
cd "C:\Program Files\Amazon\AWSCLIV2"
.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped1 s3://$MyS3Bucket --no-progress
.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped2 s3://$MyS3Bucket --no-progress
.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpHash s3://$MyS3Bucket --no-progress
.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpOSVersion s3://$MyS3Bucket --no-progress

# Cleaning up
Write-Host -Fore Cyan "Cleaning up dumps, installers, etc"
del C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped1
del C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped2
del C:\Windows\Temp\$MyMemDumpHash
del C:\Windows\Temp\$MyMemDumpOSVersion
del C:\Windows\Temp\magnet.exe
del C:\Windows\Temp\winpmem.exe
#del C:\Windows\Temp\EULAaccepted.dat

cd  C:\Windows\Temp\
Write-Host -Fore Cyan "Finished!"