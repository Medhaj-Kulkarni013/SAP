#!/bin/bash

APP_URL="https://hello-python-happy-bongo-mr.cfapps.ap21.hana.ondemand.com/"
CHECK_INTERVAL=20

while true; do
  echo "🔍 Checking $APP_URL"
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL")

  if [ "$STATUS_CODE" == "200" ]; then
    echo "✅ App is healthy."
  else
    echo "🚨 App is DOWN (status $STATUS_CODE)! Triggering failover..."
    bash automation.sh
  fi

  sleep $CHECK_INTERVAL
done
