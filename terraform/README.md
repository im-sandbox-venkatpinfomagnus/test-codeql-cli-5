# Terraform Infrastructure for CodeQL Demo

This Terraform configuration deploys the Web API to Azure Web App with comprehensive security best practices and high availability.

## ⚠️ Security Notice

**This configuration intentionally contains 1 security issue for Checkov demonstration.**

All other security best practices have been properly implemented.

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.0 installed
- Azure subscription with contributor access
- Azure AD Application registered (for Web App authentication)
  - Note: Client ID can be provided or left empty for basic deployment

## Deployment

```bash
# Initialize Terraform
terraform init

# For deployment without AAD authentication (basic)
terraform plan -var="sql_admin_password=YourStrongPassword123!"
terraform apply -var="sql_admin_password=YourStrongPassword123!"

# For deployment with AAD authentication (recommended)
terraform plan \
  -var="sql_admin_password=YourStrongPassword123!" \
  -var="aad_client_id=your-aad-client-id"

terraform apply \
  -var="sql_admin_password=YourStrongPassword123!" \
  -var="aad_client_id=your-aad-client-id"
```

## Intentional Security Issues (For Checkov Demo)

This 1 issue is intentionally left for demonstration:

1. **CKV_AZURE_35**: Storage Account - Public network access enabled

## All Fixed Checkov Issues ✅

### From Latest Screenshot:
1. ✅ **CKV_AZURE_88**: App Service health check configured (`/health` endpoint)
2. ✅ **CKV_AZURE_222**: Azure Web App public network access disabled
3. ✅ **CKV_AZURE_13**: App Service Authentication enabled (using auth_settings_v2)
4. ✅ **CKV_AZURE_97**: App Service Plan is zone redundant (Premium v3 SKU)
5. ✅ **CKV_AZURE_190**: Storage blobs restrict public access (`allow_nested_items_to_be_public = false`)
6. ✅ **CKV_AZURE_33**: Storage logging enabled for Queue service (read, write, delete)
7. ✅ **CKV_GITHUB_7**: GitHub Actions workflow permissions not set to write-all

### Previously Fixed:
8. ✅ **CKV2_AZURE_8**: Key Vault configured with private endpoint
9. ✅ **CKV_AZURE_11**: SQL Database firewall restrictions (except intentional demo rule)
10. ✅ **CKV_AZURE_28**: SQL Database zone redundancy enabled
11. ✅ **CKV_AZURE_184**: Ledger feature enabled on SQL Database
12. ✅ **CKV_AZURE_109**: Email notifications to admins for SQL Server
13. ✅ **CKV_AZURE_33**: Storage encrypted with Customer Managed Key
14. ✅ **CKV_AZURE_229**: SQL Server auditing retention 90+ days
15. ✅ **CKV_AZURE_23**: SQL Server auditing enabled
16. ✅ **CKV2_AZURE_38**: Storage SAS expiration policy configured

## Security Features Implemented ✅

### Networking
✅ Virtual Network created
✅ Private endpoint subnet configured
✅ Web App VNet integration subnet configured
✅ VNet integration enabled for Web App

### Storage Account
✅ HTTPS enforced
✅ Minimum TLS version 1.2
✅ Infrastructure encryption enabled
✅ Customer Managed Key (CMK) encryption
✅ Shared key authorization disabled
✅ Public blob access disabled
✅ SAS expiration policy (1 hour)
✅ Blob versioning enabled
✅ Blob deletion retention (7 days)
✅ Container deletion retention (7 days)
✅ Queue logging enabled (read, write, delete)
✅ User assigned identity for encryption

### App Service Plan
✅ Premium v3 SKU for production
✅ Zone redundancy enabled

### Web App
✅ HTTPS only enforced
✅ Public network access disabled
✅ Authentication enabled (Azure AD v2)
✅ Token store enabled
✅ Health check endpoint (/health)
✅ Client certificates required
✅ Managed identity configured
✅ Always on enabled
✅ Minimum TLS version 1.2
✅ HTTP/2 enabled
✅ Remote debugging disabled
✅ FTPS only mode
✅ Application and HTTP logging enabled
✅ VNet integration configured

### SQL Server & Database
✅ Minimum TLS version 1.2
✅ Public network access disabled
✅ Azure AD authentication enabled
✅ Zone redundancy enabled
✅ Ledger feature enabled
✅ Transparent Data Encryption (TDE)
✅ Long-term backup retention
✅ Short-term backup retention (7 days)
✅ Extended auditing (90+ days)
✅ Security alert policy enabled
✅ Email notifications to admins
✅ Vulnerability assessment configured

### Key Vault
✅ Public network access disabled
✅ Private endpoint configured
✅ Purge protection enabled
✅ Soft delete (90-day retention)
✅ RBAC authorization enabled
✅ Network ACLs (deny by default)
✅ Customer Managed Keys stored

### GitHub Actions
✅ Workflow permissions properly scoped
✅ No write-all permissions

## Architecture Highlights

- **High Availability**: Zone redundancy for App Service and SQL Database
- **Security**: Private endpoints, authentication, encryption
- **Compliance**: Ledger enabled, 90+ day audit retention
- **Monitoring**: Application Insights, logging, security alerts
- **Network Isolation**: VNet integration and private endpoints
- **Authentication**: Azure AD integration for Web App

## Health Check Endpoint

The Web App requires a health check endpoint at `/health`. Ensure your application implements this endpoint:

```csharp
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
```

## Outputs

- `web_app_url` - URL of the deployed Web App
- `web_app_name` - Name of the Web App
- `sql_server_fqdn` - FQDN of the SQL Server (sensitive)
- `resource_group_name` - Name of the resource group
