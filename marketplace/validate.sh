#!/bin/bash

#
# This is a sketch of a script to do schema validation for mkpl
#

rm -r ./validate/
mkdir validate
cd validate

wget -O buildpackage.zip 'https://sdaviesarmne.blob.core.windows.net/templatevalidation/buildpackage.zip?sv=2015-12-11&si=templatevalidation-read&sr=b&sig=M3OSBx7FeuQImc4riz%2BgQ4ukG6QwoHvQfoO3eLZfvvc%3D'
unzip buildpackage.zip

npm install

grunt --version
npm --version
node --version

mkdir pkg1
cp ../createUiDefinition.json pkg1/
# why? vvv
mv pkg1/createUiDefinition.json pkg1/createUIDefinition.json
cp ../../singledc/mainTemplate.json pkg1/

# --force used because a "warning" halts execution
grunt --force --folder=./pkg1 test >errors.txt
