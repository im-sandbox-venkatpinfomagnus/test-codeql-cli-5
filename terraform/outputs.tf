output "web_app_url" {
  description = "URL of the deployed Web App"
  value       = "https://${azurerm_windows_web_app.main.default_hostname}"
}

output "web_app_name" {
  description = "Name of the Web App"
  value       = azurerm_windows_web_app.main.name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}
