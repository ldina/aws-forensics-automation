#!/usr/bin/env bash
# https://github.com/ldina
# Author: Lorenzo Dina - ldina - @joecondo
# Copyright 2022 Lorenzo Dina
# v0.1 - "Initial Release"

sudo yum update -y
sudo yum install -y git python37
sudo python3 -m ensurepip --upgrade
git clone https://github.com/RhinoSecurityLabs/dsnap.git
cd dsnap
curl -O https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py --user
pip install -U pip
pip install 'dsnap[cli]'
aws configure