#!/bin/bash
apt-get update
apt-get install -y cifs-utils jq curl

MOUNT_POINT="/mnt/azfiles"
mkdir -p $MOUNT_POINT

# Get token to access Key Vault
ACCESS_TOKEN=$(curl -H "Metadata:true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" \
  | jq -r .access_token)

# Get storage key from Key Vault
STORAGE_KEY=$(curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://${keyvault_name}.vault.azure.net/secrets/${secret_name}?api-version=7.2" \
  | jq -r .value)

# Mount Azure Files
mount -t cifs //${storage_account}.file.core.windows.net/${file_share} $MOUNT_POINT \
  -o vers=3.0,username=${storage_account},password=$STORAGE_KEY,dir_mode=0777,file_mode=0777,serverino

# Add to fstab for persistence
echo "//${storage_account}.file.core.windows.net/${file_share} $MOUNT_POINT cifs vers=3.0,username=${storage_account},password=$STORAGE_KEY,dir_mode=0777,file_mode=0777,serverino 0 0" >> /etc/fstab

