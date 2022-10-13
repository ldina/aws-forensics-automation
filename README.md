# aws-forensics-automation
AWS Forensics and Incident Response Automation Tools

These scripts are for forensics practioneer <b>aware of the risks </b> of using this software during an investigation or incdent response. Please test the tools and your knowledge of AWS in a dedicated enviroment before using it in a real world case.

The quality of the coding is amateurish level since is to be considered a learning experiment to solve some challenges of a forensics analyst, that has never been a professional developer, approaching case of the AWS scale.

The code of the win memory dumps scripts benefits from snippets, optimizations and ideas of the CSIRT-Collect project from dwmetz Doug Metz that I discovered near the end of this journey https://github.com/dwmetz/CSIRT-Collect


## ec2-win-DumpMemory-net

Functions:
- download Magnet Ram Capture, WinPmem, AWS CLI from internet to your AWS EC2 instance
- capture a memory image with Magnet Ram Capture and WinPmem
- hash the captured dump files
- capture OS build info
- transfer the artifacts back to an AWS S3 bucket

Prerequisites:
- Internet connection for files download
- Updated URL references for tool download
- An S3 Bucket accessible by the EC2 instance for artificats upload

- OPTIONAL: if you run the script via AWS SSM the EC2 instance must have assigned an IAM role that includes SSM support


## ec2-win-DumpMemory-isolated
Functions:
- download Magnet Ram Capture, WinPmem, AWS CLI from a preconfigured AWS S3 bucket to your AWS EC2 instance
- capture a memory image with Magnet Ram Capture and WinPmem
- hash the captured dump files
- capture OS build info
- transfer the artifacts back to an AWS S3 bucket

Prerequisites:
- An S3 Bucket pre-configured with binaries of the tool to be downloaded (see setup-DumpMemory-isolated )
- An S3 Bucket accessible by the EC2 instance for artificats upload

- OPTIONAL: if you run the script via AWS SSM the EC2 instance must have assigned an IAM role that includes SSM support


## setup-DumpMemory-isolated
Functions:
- download Magnet Ram Capture, WinPmem, AWS CLI from internet to your AWS S3 bucket

Prerequisites:
- AWS CloudShell in powershell mode (pwsh)
- Internet connection to download the files
- An S3 Bucket accessible by AWS CloudShell 
- Updated URL references for tool download
