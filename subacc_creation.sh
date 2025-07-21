#!/bin/bash

echo "🔐 Logging in to SAP BTP CLI..."
btp login --url https://cli.btp.cloud.sap
if [ $? -ne 0 ]; then
  echo "❌ Login failed."
  exit 1
fi

# === Randomized Unique Identifiers ===
UUID_SUFFIX=$(cat /proc/sys/kernel/random/uuid | cut -d'-' -f1)
TIMESTAMP=$(date +%s)

SUBACCOUNT_SUBDOMAIN="subacc-${UUID_SUFFIX}-${TIMESTAMP}"
SUBACCOUNT_DISPLAY_NAME="Subaccount ${UUID_SUFFIX} ${TIMESTAMP}"
CF_ORG_NAME="org-${UUID_SUFFIX}-${TIMESTAMP}"

echo "🆕 Generated:"
echo "  - Subdomain: $SUBACCOUNT_SUBDOMAIN"
echo "  - Display Name: $SUBACCOUNT_DISPLAY_NAME"
echo "  - CF Org Name: $CF_ORG_NAME"

# === Random Region Selection ===
REGIONS=("us10" "ap21")
SELECTED_REGION="${REGIONS[$((RANDOM % ${#REGIONS[@]}))]}"

echo "🌍 Creating subaccount in region: $SELECTED_REGION"
btp create accounts/subaccount \
  --subdomain "$SUBACCOUNT_SUBDOMAIN" \
  --display-name "$SUBACCOUNT_DISPLAY_NAME" \
  --region "$SELECTED_REGION"

echo "⏳ Waiting for subaccount provisioning..."
sleep 45

# === Get Subaccount ID ===
SUBACC_ID=$(btp list accounts/subaccount | grep "$SUBACCOUNT_SUBDOMAIN" | awk '{print $1}')
if [ -z "$SUBACC_ID" ]; then
  echo "❌ Failed to retrieve Subaccount ID."
  exit 1
fi
echo "✅ Subaccount ID: $SUBACC_ID"

# === Enable Cloud Foundry Environment ===
echo "🔧 Enabling Cloud Foundry with Org: $CF_ORG_NAME..."
btp create accounts/environment-instance \
  --subaccount "$SUBACC_ID" \
  --display-name "$SUBACCOUNT_SUBDOMAIN" \
  --environment "cloudfoundry" \
  --service "cloudfoundry" \
  --plan "trial" \
  --parameters '{"instance_name": "'$CF_ORG_NAME'"}'

echo "⏳ Waiting for Cloud Foundry environment to be ready..."
sleep 30

# === CF Login using SSO ===
if [ "$SELECTED_REGION" == "us10" ]; then
  CF_API="https://api.cf.us10-001.hana.ondemand.com"
elif [ "$SELECTED_REGION" == "ap21" ]; then
  CF_API="https://api.cf.ap21.hana.ondemand.com"
else
  echo "Unknown region: $SELECTED_REGION"
  exit 1
fi

echo "🌐 Logging into Cloud Foundry via SSO..."
cf login -a "$CF_API" --sso
if [ $? -ne 0 ]; then
  echo "❌ CF login failed."
  exit 1
fi

# === Target Org and Create Space ===
echo "🎯 Targeting Org: $CF_ORG_NAME"
cf target -o "$CF_ORG_NAME"

SPACE_NAME="dev"
echo "🚀 Creating space: $SPACE_NAME"
cf create-space "$SPACE_NAME"

if [ $? -eq 0 ]; then
  echo "✅ Space '$SPACE_NAME' created successfully in Org '$CF_ORG_NAME'."
else
  echo "❌ Failed to create space."
  exit 1
fi

# === Entitlement for CF ===
CF_MEMORY=1  # 1 unit = 1 GB

echo "Assigning Cloud Foundry Runtime entitlement ($CF_MEMORY unit)..."
btp assign accounts/entitlement \
  --to-subaccount "$SUBACC_ID" \
  --for-service "APPLICATION_RUNTIME" \
  --plan "MEMORY" \
  --amount "$CF_MEMORY"

sleep 10

if [ $? -ne 0 ]; then
  echo "❌ Failed to assign Cloud Foundry Runtime entitlement."
  sleep 2
  exit 1
fi
echo "✅ Entitlement assigned successfully."


