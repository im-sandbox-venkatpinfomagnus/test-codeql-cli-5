terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Storage account - ISSUE #1: Public network access enabled (keeping for demo)
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # ISSUE: Public network access enabled (intentional for demo)
  public_network_access_enabled = true
  
  https_traffic_only_enabled = true
  min_tls_version = "TLS1_2"
  infrastructure_encryption_enabled = true
  
  shared_access_key_enabled = false
  
  # Fixed: Allow blob public access disabled
  allow_nested_items_to_be_public = false
  
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.storage.id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage.id
  }
  
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.storage.id]
  }
  
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 7
    }
    
    container_delete_retention_policy {
      days = 7
    }
  }
  
  # Fixed: Queue logging enabled with all operations
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }
  
  sas_policy {
    expiration_period = "00.01:00:00"
    expiration_action = "Log"
  } 
}

# User assigned identity for storage account
resource "azurerm_user_assigned_identity" "storage" {
  name                = "id-storage-${var.storage_account_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Key Vault Key for storage encryption
resource "azurerm_key_vault_key" "storage" {
  name         = "storage-encryption-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  
  depends_on = [azurerm_role_assignment.current_user_keyvault]
}

# Grant storage identity access to Key Vault
resource "azurerm_role_assignment" "storage_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage.principal_id
}

# App Service Plan - Fixed: Zone redundancy enabled
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Windows"
  sku_name            = "P1v3"  # Premium v3 for zone redundancy
  
  # Fixed: Zone redundancy enabled
  zone_balancing_enabled = true
}

# Web App - Fixed: All authentication and health check issues
resource "azurerm_windows_web_app" "main" {
  name                = var.web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  
  https_only = true
  
  # Fixed: Public network access disabled
  public_network_access_enabled = false
  
  client_certificate_enabled = true
  client_certificate_mode    = "Required"
  
  identity {
    type = "SystemAssigned"
  }
  
  # Fixed: Authentication enabled using auth_settings_v2
  auth_settings_v2 {
    auth_enabled = true
    require_authentication = true
    unauthenticated_action = "RedirectToLoginPage"
    default_provider = "azureactivedirectory"
    
    login {
      token_store_enabled = true
    }
    
    active_directory_v2 {
      client_id = var.aad_client_id
      tenant_auth_endpoint = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
      allowed_audiences = ["api://${var.aad_client_id}"]
    }
  }
  
  site_config {
    always_on = true
    minimum_tls_version = "1.2"
    http2_enabled = true
    managed_pipeline_mode = "Integrated"
    remote_debugging_enabled = false
    ftps_state = "FtpsOnly"
    
    # Fixed: Health check path configured
    health_check_path = "/health"
    health_check_eviction_time_in_min = 5
    
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }
  
  app_settings = {
    "ASPNETCORE_ENVIRONMENT"              = "Production"
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "ConnectionString" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=sql-connection-string)"
  }
  
  logs {
    application_logs {
      file_system_level = "Information"
    }
    
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-codeql-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  retention_in_days   = 90
}

# SQL Server - ISSUE #2: Firewall allows all IPs (keeping for demo)
resource "azurerm_mssql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  minimum_tls_version = "1.2"
  public_network_access_enabled = false
  
  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
  
  identity {
    type = "SystemAssigned"
  }
}

# SQL Database - Fixed: Zone redundancy and ledger enabled
resource "azurerm_mssql_database" "main" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  sku_name       = "S1"  # Changed to Standard for zone redundancy support
  
  transparent_data_encryption_enabled = true
  
  # Fixed: Zone redundancy enabled
  zone_redundant = true
  
  # Fixed: Ledger enabled for cryptographic proof
  ledger_enabled = true
  
  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year      = 1
  }
  
  short_term_retention_policy {
    retention_days = 7
  }
}

# Fixed: SQL Server Extended Auditing Policy with 90+ days retention
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id                               = azurerm_mssql_server.main.id
  storage_endpoint                        = azurerm_storage_account.main.primary_blob_endpoint
  retention_in_days                       = 90
  log_monitoring_enabled                  = true
  storage_account_subscription_id         = data.azurerm_client_config.current.subscription_id
}

# Fixed: SQL Database Extended Auditing Policy
resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id                             = azurerm_mssql_database.main.id
  storage_endpoint                        = azurerm_storage_account.main.primary_blob_endpoint
  retention_in_days                       = 90
  log_monitoring_enabled                  = true
}

# SQL Server Security Alert Policy with email notifications enabled
resource "azurerm_mssql_server_security_alert_policy" "main" {
  resource_group_name        = azurerm_resource_group.main.name
  server_name                = azurerm_mssql_server.main.name
  state                      = "Enabled"
  email_addresses            = ["security@example.com"]
  retention_days             = 30
  
  # Fixed: Email to admins and co-admins enabled
  email_account_admins       = true
  
  disabled_alerts = []
}

# SQL Server Vulnerability Assessment
resource "azurerm_mssql_server_vulnerability_assessment" "main" {
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main.id
  storage_container_path          = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.vulnerability_assessment.name}/"
  
  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = ["security@example.com"]
  }
  
  depends_on = [azurerm_storage_container.vulnerability_assessment]
}

# ISSUE: Firewall rule allowing all IPs (intentional for demo)
resource "azurerm_mssql_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# Key Vault - Fixed: Private endpoint configuration
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  # Fixed: Public network access disabled
  public_network_access_enabled = false
  
  purge_protection_enabled = true
  soft_delete_retention_days = 90
  enable_rbac_authorization = true
  
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${var.key_vault_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

# Virtual Network for private endpoints
resource "azurerm_virtual_network" "main" {
  name                = "vnet-codeql-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet for private endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for Web App VNet integration
resource "azurerm_subnet" "webapp" {
  name                 = "snet-webapp"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "webapp-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# VNet integration for Web App
resource "azurerm_app_service_virtual_network_swift_connection" "webapp" {
  app_service_id = azurerm_windows_web_app.main.id
  subnet_id      = azurerm_subnet.webapp.id
}

data "azurerm_client_config" "current" {}
