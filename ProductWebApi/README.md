# ProductWebApi - CodeQL Security Demo

This is a deliberately vulnerable .NET Web API project designed to demonstrate security vulnerabilities that CodeQL can detect.

## 🚨 Security Vulnerabilities Included

### 1. **SQL Injection (CWE-89)**
- **Location**: `ProductsController.SearchProducts()`, `AdvancedSearch()`, `LegacySearch()`
- **Issue**: Direct string concatenation in SQL queries
- **Example**: `SearchProducts()` concatenates user input directly into SQL query

### 2. **Hardcoded Credentials (CWE-798)**
- **Location**: `Program.cs`, `ProductsController`, `AppDbContext.OnModelCreating()`
- **Issue**: Database passwords and API keys in source code
- **Example**: Connection string with hardcoded password in `Program.cs`

### 3. **XML External Entity (XXE) Injection (CWE-611)**
- **Location**: `ProductsController.ImportProductsFromXml()`
- **Issue**: XMLDocument with default settings allows XXE attacks
- **Example**: `XmlDocument.LoadXml()` without security configuration

### 4. **Path Traversal (CWE-22)**
- **Location**: `ProductsController.UploadCatalog()`
- **Issue**: User-controlled file paths without validation
- **Example**: `Path.Combine("uploads", fileName)` without sanitization

### 5. **Command Injection (CWE-78)**
- **Location**: `ProductsController.BackupDatabase()`
- **Issue**: User input directly passed to system commands
- **Example**: Unsanitized `backupPath` in command execution

### 6. **Information Disclosure (CWE-200)**
- **Location**: Multiple exception handlers
- **Issue**: Detailed error messages with stack traces exposed to clients
- **Example**: Exception details returned in API responses

### 7. **Weak Random Number Generation (CWE-338)**
- **Location**: `ProductsController.GenerateWeakApiKey()`
- **Issue**: Using `System.Random` for security-sensitive operations
- **Example**: API key generation using non-cryptographic random

### 8. **Missing Authorization (CWE-862)**
- **Location**: `DeleteProduct()`, `DeleteAllProducts()`, `GetUserProducts()`
- **Issue**: Sensitive operations without authentication/authorization
- **Example**: Admin functions accessible without authorization

### 9. **Insecure Direct Object Reference (CWE-639)**
- **Location**: `ProductsController.GetUserProducts()`
- **Issue**: Users can access other users' data without authorization
- **Example**: Any user can query any userId's products

### 10. **Resource Leaks (CWE-404)**
- **Location**: `AppDbContext.GetProductsUnsafe()`, `LegacySearch()`
- **Issue**: Database connections not properly disposed
- **Example**: SqlConnection opened but never closed

### 11. **Insecure CORS Configuration (CWE-942)**
- **Location**: `Program.cs`
- **Issue**: Overly permissive CORS policy
- **Example**: `AllowAnyOrigin()` allows any domain to access API

### 12. **Missing HTTPS Enforcement (CWE-319)**
- **Location**: `Program.cs`
- **Issue**: HTTPS redirection disabled
- **Example**: Commented out `app.UseHttpsRedirection()`

## 🎯 Demo Instructions

### 1. **Setup Project**
```bash
cd ProductWebApi
dotnet restore
dotnet build
```

### 2. **Run the Application**
```bash
dotnet run
```
Access Swagger UI at: `https://localhost:5001/swagger`

### 3. **Test Vulnerable Endpoints**

**SQL Injection Test:**
```bash
# This will cause SQL injection
GET /api/products/search/'; DROP TABLE Products; --
```

**Path Traversal Test:**
```bash
# This will attempt directory traversal
POST /api/products/upload-catalog
# With fileName: "../../../windows/system32/config/sam"
```

**XXE Test:**
```bash
POST /api/products/import-xml
# With XML containing external entity references
```

### 4. **CodeQL Analysis**
1. Initialize CodeQL database
2. Run security queries
3. Review alerts for each vulnerability type
4. Show how CodeQL pinpoints exact vulnerable code locations

## 🔧 Running CodeQL

```bash
# Initialize CodeQL database
codeql database create codeql-db --language=csharp

# Run analysis
codeql database analyze codeql-db csharp-security-and-quality.qls --format=json --output=results.json

# View results
codeql bqrs decode results.bqrs --format=json
```

## 📚 Educational Value

This project demonstrates:
- Common web application vulnerabilities
- How static analysis tools detect security issues
- The importance of secure coding practices
- OWASP Top 10 vulnerabilities in real code

**Note**: This code is intentionally vulnerable and should NEVER be used in production environments.

## 🛡️ Secure Alternatives

Each vulnerability includes comments showing the secure alternative approach:
- Parameterized queries instead of string concatenation
- Configuration-based connection strings
- Secure XML parsing with DTD disabled
- Path sanitization and validation
- Authorization middleware
- Proper resource disposal patterns