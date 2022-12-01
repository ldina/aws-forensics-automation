#!/usr/bin/env bash
# https://github.com/ldina
# Author: Lorenzo Dina - ldina - @joecondo
# Copyright 2022 Lorenzo Dina
# v0.1 - "Initial Release"
DownloadPath="/data"
S3Path="s3://dsnap/"
AwsRegion="eu-west-1"

cd $DownloadPath
echo "Downloading the requested Snapshot from AWS to DownloadPath"
dsnap --region $AwsRegion get $1
echo "Hashing the requested Snapshot"
sha1sum $1.img > $s1.sha1
echo "Uploading the requested Snapshot to S3"
aws s3 cp $DownloadPath/$1.img $S3Path