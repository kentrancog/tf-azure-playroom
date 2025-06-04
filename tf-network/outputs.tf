# output "vm_public_ip" {
#   description = "The public IP address of the Linux VM"
#   value       = azurerm_public_ip.vm_public_ip.ip_address
# }

# output "private_endpoint_ip" {
#   description = "The private IP assigned to the Azure Private Endpoint. This is what the resources in this subscriptions vNet should resolve to when accessing the Azure File Share.  Other subscriptions will resolve to the endpoint IP thats created as part of their vNets"
#   value       = azurerm_private_endpoint.fileshare_endpoint.private_service_connection[0].private_ip_address
# }

# output "storage_share_url" {
#   description = "The URL for the Azure File Share"
#   value       = azurerm_storage_share.premium_share.url
# }

# output "storage_share_unc_path_windows" {
#   description = "The Windows UNC path for the Azure File Share.  Use \"terraform output --raw <output_name>\" due to escaping issues"
#   value       = "\\\\${azurerm_storage_account.premium_files.name}.file.core.windows.net\\${azurerm_storage_share.premium_share.name}"
# }

# output "storage_account_resource_id" {
#   description = "The resource ID for the Azure Storage Account used by other subscriptions to create private endpoints"
#   value       = azurerm_storage_account.premium_files.id
# }