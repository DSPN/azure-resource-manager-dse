#!/bin/bash

# Generate a provision.json file
python opsCenter.py

# Provision a new cluster using that file
curl --insecure -H "Accept: application/json" -X POST http://127.0.0.1:8888/provision -d @provision.json

