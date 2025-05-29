# Step 1: Register the Microsoft.AAD resource provider (if not already done)
az provider register --namespace Microsoft.AAD
az provider show --namespace Microsoft.AAD --query "registrationState" # Wait for "Registered"

# Step 2: Define variables (replace with your actual values)
RESOURCE_GROUP_NAME="MyAaddsRg"
LOCATION="AustraliaEast" # e.g., EastUS, WestEurope
AADDS_DOMAIN="adds.hadouken.com" # Choose a unique DNS domain name
VNET_NAME="vnet"
VNET_RG_NAME="network-resources" # Resource group of your VNet if different
SUBNET_NAME="adds-subnet" # Dedicated empty subnet
AADDS_SKU="Standard" # Standard, Enterprise, or Premium
NOTIFY_GLOBAL_ADMINS="Enabled" # Enabled or Disabled
NOTIFY_DC_ADMINS="Enabled" # Enabled or Disabled

# Step 3: Create a resource group for Azure AD DS (if it doesn't exist)
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"

# Step 4: Get the Subnet ID
# Ensure your VNet and Subnet are already created.
# If VNet RG is same as AADDS RG:
# SUBNET_ID=$(az network vnet subnet show --resource-group "$RESOURCE_GROUP_NAME" --vnet-name "$VNET_NAME" --name "$SUBNET_NAME" --query id -o tsv)
# If VNet RG is different:
SUBNET_ID=$(az network vnet subnet show --resource-group "$VNET_RG_NAME" --vnet-name "$VNET_NAME" --name "$SUBNET_NAME" --query id -o tsv)

if [ -z "$SUBNET_ID" ]; then
    echo "Error: Subnet ID could not be retrieved. Ensure VNet and Subnet exist and names/RGs are correct."
    exit 1
fi

echo "Using Subnet ID: $SUBNET_ID"

# Step 5: Create Azure AD Domain Services
# The command is asynchronous. It will start the provisioning.
# --- Construct and Execute the command ---
# Note: The root --location parameter for the AADDS resource itself is removed as per your finding.
# The location of the AADDS resource might be inferred from the first replica set or the resource group.
az ad ds create --name "$AADDS_DOMAIN" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --domain "$AADDS_DOMAIN" \
    --sku "$AADDS_SKU" \
    --replica-sets location="$LOCATION" subnet-id="$SUBNET_ID" \
    --notify-global-admins "$NOTIFY_GLOBAL_ADMINS" \
    --notify-dc-admins "$NOTIFY_DC_ADMINS"
    # --domain-config-type "$DOMAIN_CONFIG_TYPE" \
    # --debug

# Check the exit code
if [ $? -eq 0 ]; then
    echo "Azure AD DS creation command initiated successfully."
else
    echo "Azure AD DS creation command failed with exit code $?."
fi

# You can add more parameters as needed:
#   --filtered-sync "Disabled" # Or "Enabled" for scoped sync
#   --ldaps "Disabled" # Or "Enabled" - requires cert config
#   --external-access "Disabled" # If LDAPS is enabled
#   --ntlm-v1 "Disabled" # Recommended
#   --tls-v1 "Disabled" # Recommended (enforces TLS 1.2+)
#   --sync-kerberos-passwords "Enabled"
#   --sync-ntlm-passwords "Enabled"
#   --sync-on-prem-passwords "Enabled" # If applicable

echo "Azure AD DS creation initiated. This will take a significant amount of time."
echo "You can monitor the status in the Azure portal or using:"
echo "az ad ds show --name \"$AADDS_DOMAIN_NAME\" --resource-group \"$RESOURCE_GROUP_NAME\" --query \"provisioningState\""

# To wait for completion (example polling loop - use with caution in production scripts, add timeout)
# while true; do
#   STATUS=$(az ad ds show --name "$AADDS_DOMAIN_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "provisioningState" -o tsv)
#   echo "Current provisioning state: $STATUS"
#   if [[ "$STATUS" == "Succeeded" ]]; then
#     echo "Azure AD DS successfully provisioned."
#     break
#   elif [[ "$STATUS" == "Failed" || "$STATUS" == "Canceled" ]]; then
#     echo "Azure AD DS provisioning failed or was canceled."
#     exit 1
#   fi
#   sleep 60 # Poll every 60 seconds
# done

# After successful provisioning, you'll need to update DNS settings for your VNet
# to point to the IP addresses of the Azure AD DS domain controllers.
# These IPs can be found in the Azure portal on the Azure AD DS properties page once available.
# Example (manual step or further scripting needed):
# AADDS_IP1=$(az ad ds show --name "$AADDS_DOMAIN_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "replicaSets[0].domainControllerIpAddress[0]" -o tsv)
# AADDS_IP2=$(az ad ds show --name "$AADDS_DOMAIN_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "replicaSets[0].domainControllerIpAddress[1]" -o tsv)
# echo "Update VNet DNS servers to: $AADDS_IP1, $AADDS_IP2"
# az network vnet update --resource-group "$VNET_RG_NAME" --name "$VNET_NAME" --dns-servers "$AADDS_IP1" "$AADDS_IP2"
