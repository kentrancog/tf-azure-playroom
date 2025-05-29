# Step 1: Define variables (ensure these match the instance you want to delete)
RESOURCE_GROUP_NAME="MyAaddsRg"
AADDS_DOMAIN_NAME="adds.yourdomain.com" # The DNS domain name of the AADDS instance

# Step 2: Delete the Azure AD Domain Services instance
echo "WARNING: This will permanently delete Azure AD Domain Services: $AADDS_DOMAIN_NAME."
echo "Ensure this is the intended action."
# Add --yes to bypass confirmation, otherwise it will prompt.
az ad ds delete --name "$AADDS_DOMAIN_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --yes # Remove --yes for an interactive prompt

echo "Azure AD DS deletion initiated for $AADDS_DOMAIN_NAME."
echo "This process may take some time."

# Step 3: Delete the resource group (optional, if it was dedicated)
# Ensure no other critical resources are in this RG if you uncomment this.
# echo "Optionally deleting the resource group: $RESOURCE_GROUP_NAME"
# az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait
