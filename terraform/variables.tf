variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-codeql-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
  default     = "stcodeqldemo001"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "asp-codeql-demo"
}

variable "web_app_name" {
  description = "Name of the Web App"
  type        = string
  default     = "app-codeql-demo-api"
}

variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
  default     = "sql-codeql-demo"
}

variable "sql_database_name" {
  description = "Name of the SQL Database"
  type        = string
  default     = "sqldb-codeql-demo"
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
  default     = "kv-codeql-demo"
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "aad_client_id" {
  description = "Azure AD Application Client ID for authentication"
  type        = string
  default     = ""  # Replace with actual client ID
}
