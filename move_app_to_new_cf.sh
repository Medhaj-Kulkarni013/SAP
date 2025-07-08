#!/bin/bash

API_ENDPOINT="https://api.cf.us10-001.hana.ondemand.com/"
ORG="ee55f632trial_test-z2ow5x2b"
SPACE="dev"
APP_NAME="hello-python"
APP_DIR="."  # Current folder

cf login -a $API_ENDPOINT
cf target -o $ORG -s $SPACE

cd $APP_DIR
cf push $APP_NAME
