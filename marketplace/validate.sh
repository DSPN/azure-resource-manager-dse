#!/bin/bash

#
# This is a sketch of a script to do schema validation for mkpl
#

mkdir validate
cd validate

wget -O buildpackage.zip 'https://sdaviesarmne.blob.core.windows.net/templatevalidation/buildpackage.zip?sv=2015-12-11&si=templatevalidation-read&sr=b&sig=M3OSBx7FeuQImc4riz%2BgQ4ukG6QwoHvQfoO3eLZfvvc%3D'
unzip buildpackage.zip

npm install

grunt --version
npm --version
node --version

mkdir pkg1
cp ../createUIDefinition.json pkg1/
cp ../../singledc/mainTemplate.json pkg1/

# --force used because a "warning" halts execution
grunt --force --folder=./pkg1 test >errors.txt
