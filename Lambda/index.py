#  Copyright 2021 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#  This file is licensed to you under the AWS Customer Agreement (the "License").
#  You may not use this file except in compliance with the License.
#  A copy of the License is located at http://aws.amazon.com/agreement/ .
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
#  See the License for the specific language governing permissions and limitations under the License.

import boto3
import os
import uuid
import time

def lambda_handler(event, context):
    try:
        if not isinstance(event['InstanceId'], list):
            event['InstanceId'] = [event['InstanceId']]
        
        #Init SSM client (IRAutomation: Member Account)         
        sts = boto3.client('sts')
        ir_automation_credentials = sts.assume_role(
            RoleArn='arn:{}:iam::{}:role/IRAutomation'.format(
                os.environ.get("Partition", 'aws'),
                event['Account']
            ),
            RoleSessionName="{}-snapshot".format(str(uuid.uuid4())[:5])
        )['Credentials']
        session = boto3.Session(
            aws_access_key_id=ir_automation_credentials['AccessKeyId'],
            aws_secret_access_key=ir_automation_credentials['SecretAccessKey'],
            aws_session_token=ir_automation_credentials['SessionToken']
        )
        ssm = session.client('ssm', region_name=event['Region'])
        
        s3_sts = boto3.client('sts')
      
        output = {}

        for instance in event['InstanceId']:
            
            s3_prefix = "{1}/{2}/{0}/memory/*".format(
                instance,
                event['CaseId'],
                event['Account'],                
            )

            session_policy=f'''{{
                "Version":"2012-10-17",
                "Statement":{{
                    "Sid":"S3LeastPrivilege",
                    "Effect":"Allow",
                    "Action":["s3:PutObject", "s3:PutObjectAcl"],
                    "Resource":["arn:aws:s3:::{os.environ.get('S3Bucket')}/{s3_prefix}"]
                    }}
            }}'''  

            #Retrieve temporary credentials for S3 memory artefact upload from target instance        
            restricted_s3_credentials = s3_sts.assume_role(
                RoleArn=os.environ.get("S3CopyRole"),
                RoleSessionName="{}-s3copy".format(str(uuid.uuid4())[:5]),
                DurationSeconds=3600,
                Policy=session_policy
            )['Credentials']
            
            sizetag = '--metadata OriginalSize=$MEMSIZE'
            acl = '--acl bucket-owner-full-control'

            s3 = 'aws s3 cp - s3://{3}/{1}/{2}/{0}/memory/{0}.raw'.format(
                instance,
                event['CaseId'],
                event['Account'],
                os.environ.get("S3Bucket"),
            )

            commands1 = [
                '$MyMemDumpInstanceId =""',
                '$MyMemDumpInstanceIdTimeStamped =""',
                '$MyMemDumpInstanceIdTimeStamped1 =""',
                '$MyMemDumpInstanceIdTimeStamped2 =""',
                'Set-DefaultAWSRegion -Region eu-west-1',
                '$MyMemDumpInstanceId = Get-EC2InstanceMetadata -Category InstanceId',
                '$MyS3Bucket = "localec2dump"',
                '$AwsCliURL = "https://awscli.amazonaws.com/AWSCLIV2.msi"',
                '$MagnetURL = "https://storage.googleapis.com/mfi-files/free_tools/MagnetRAMCapture/MRCv120.exe"',
                '$WinPmemURL = "https://github.com/Velocidex/WinPmem/releases/download/v4.0.rc1/winpmem_mini_x64_rc2.exe"',
                'msiexec.exe /i $AwsCliURL /q',
                'cd "C:\Windows\Temp\"',
                'curl $MagnetURL -outfile magnet.exe',
                'curl $WinPmemURL -outfile winpmem.exe',
                '$MyDate = Get-Date -Format "yyyyMMdd"',
                '$MyTime = Get-Date -Format "HHmmss"',
                '$MyTimeStamp = $MyDate',
                '$MyTimeStamp += "T"',
                '$MyTimeStamp += $MyTime',
                '$MyMemDumpInstanceIdTimeStamped = $MyTimeStamp',
                '$MyMemDumpInstanceIdTimeStamped += "_"',
                '$MyMemDumpInstanceIdTimeStamped += $MyMemDumpInstanceId',
                '$MyMemDumpInstanceIdTimeStamped1 = $MyMemDumpInstanceIdTimeStamped',
                '$MyMemDumpInstanceIdTimeStamped1 += "_winpmem.raw"',
                '.\winpmem.exe $MyMemDumpInstanceIdTimeStamped1',
                '$MyMemDumpInstanceIdTimeStamped2 = $MyMemDumpInstanceIdTimeStamped',
                '$MyMemDumpInstanceIdTimeStamped2 += "_magnetram.raw"',
                '.\magnet.exe /accepteula /silent /go "C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped2"',
                'Start-Sleep -Seconds 5',
                'Wait-Process -name "magnet"',
                '$MyMemDumpOSVersion = $MyMemDumpInstanceIdTimeStamped',
                '$MyMemDumpOSVersion += "_osversion.txt"',
                '[System.Environment]::OSVersion.Version > $MyMemDumpOSVersion',
                '$MyMemDumpHash = $MyMemDumpInstanceIdTimeStamped',
                '$MyMemDumpHash += "_hash.txt"',
                'Get-FileHash C:\Windows\Temp\*.raw -Algorithm SHA1 | Format-List >$MyMemDumpHash',
                'cd "C:\Program Files\Amazon\AWSCLIV2"',
                '.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped1 s3://$MyS3Bucket --no-progress',
                '.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped2 s3://$MyS3Bucket --no-progress',
                '.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpHash s3://$MyS3Bucket --no-progress',
                '.\aws.exe s3 cp C:\Windows\Temp\$MyMemDumpOSVersion s3://$MyS3Bucket --no-progress',
                '#del C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped1',
                '#del C:\Windows\Temp\$MyMemDumpInstanceIdTimeStamped2',
                '#del C:\Windows\Temp\$MyMemDumpHash',
                '#del C:\Windows\Temp\$MyMemDumpOSVersion',
                '#del C:\Windows\Temp\magnet.exe',
                '#del C:\Windows\Temp\winpmem.exe',
                '#del C:\Windows\Temp\EULAaccepted.dat',
            ]
            commands2 = [
                '#!/bin/bash',
                '#sleep 10',
                "export MEMSIZE=`awk '/MemTotal/ {print $2/1024/1024}' /proc/meminfo`",
                'export AWS_ACCESS_KEY_ID={}'.format(restricted_s3_credentials['AccessKeyId']),
                'export AWS_SECRET_ACCESS_KEY={}'.format(restricted_s3_credentials['SecretAccessKey']),
                'export AWS_SESSION_TOKEN={}'.format(restricted_s3_credentials['SessionToken']),
                'export AWS_DEFAULT_REGION={}'.format(event['Region']),
                'aws configure set default.s3.max_concurrent_requests 20',
                
            ]

            response1 = ssm.send_command(
                InstanceIds= [instance],
                DocumentName='AWS-RunPowerShellScript',
                Parameters={
                    'commands': commands1,
                    'executionTimeout': ['43200'] 
                },
                Comment='Insert LiME'
            )
            
            time.sleep(30)
            
            response2 = ssm.send_command(
                InstanceIds= [instance],
                DocumentName='AWS-RunPowerShellScript',
                Parameters={
                    'commands': commands2,
                    'executionTimeout': ['43200'] 
                },
                Comment='Dump to S3'
            )
            output[instance] = [response1['Command']['CommandId'], response2['Command']['CommandId']]

            s3_export = dict ()
            s3_export['ArtifactRoot'] = 's3://{3}/{1}/{2}/{0}/memory/'.format(
                instance,
                event['CaseId'],
                event['Account'],
                os.environ.get("S3Bucket"),
            )

            s3_export['S3URL'] = '{0}.raw'.format(
                instance
            )


        return {
            "Output": output,
            "S3": s3_export
        }

    except Exception as e:
        raise
