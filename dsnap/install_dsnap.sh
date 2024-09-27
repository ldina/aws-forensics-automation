#!/usr/bin/env bash
# https://github.com/ldina
# Author: Lorenzo Dina - ldina - @joecondo
# Copyright 2022 - 2024 Lorenzo Dina
# v0.2 - "Improvements Release"

echo "Environment preparation"
echo "________________________________"
sudo yum update -y
sudo yum install -y git python
sudo python3 -m ensurepip --upgrade
pip install -U pip

echo "dSnap installation"
echo "________________________________"
git clone https://github.com/RhinoSecurityLabs/dsnap.git
cd dsnap
pip install 'dsnap[cli]'

echo "AWS cli configuration and accesskey"
echo "________________________________"
aws configure set aws_access_key_id AK
aws configure set aws_secret_access_key 
aws configure set default.region eu-west-1

echo "dSnap test listing snapshots"
echo "________________________________"

dsnap --region eu-west-1 list