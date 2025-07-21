#!/bin/bash
 
# ------------------ CONFIG ------------------
API_ENDPOINT="https://api.cf.ap21.hana.ondemand.com"  
ORG="4ad36fedtrial_sub1-tcp5rwi6"                                  
SPACE="dev"
APP_NAME="hello-python"
APP_DIR="."
 
# "Logging into Cloud Foundry..."
cf login -a $API_ENDPOINT
 
# "Targeting org and space..."
cf target -o "$ORG" -s "$SPACE"
 
# "Deploying app: $APP_NAME"
cd "$APP_DIR"
cf push "$APP_NAME"