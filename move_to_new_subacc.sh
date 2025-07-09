#!/bin/bash

# ------------------ CONFIG ------------------
API_ENDPOINT="https://api.cf.us10-001.hana.ondemand.com"  
ORG="ee55f632trial_test-z2ow5x2b"                                  
SPACE="dev"
APP_NAME="hello-python"
APP_DIR="." 

echo "Logging into Cloud Foundry..."
cf login -a $API_ENDPOINT

echo "Targeting org and space..."
cf target -o "$ORG" -s "$SPACE"

echo "Deploying app: $APP_NAME"
cd "$APP_DIR"
cf push "$APP_NAME"
