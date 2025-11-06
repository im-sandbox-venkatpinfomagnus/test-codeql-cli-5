# CodeQL Security Issues - Demo Checklist

This document lists all the intentional security vulnerabilities in the ProductWebApi solution that will be detected by CodeQL scanning. Use this as a reference during your security demonstration.

## 🚨 Security Vulnerabilities by Category

### 1. **SQL Injection (CWE-89)**

#### 1.1 Direct String Concatenation Patterns
- **File**: `ProductsController.cs`
- **Methods**: 
  - `SearchProducts()` - Line ~65
  - `AdvancedSearch()` - Line ~85 (commented vulnerable patterns)
  - `LegacySearch()` - Line ~330 (commented vulnerable patterns)
- **Issue**: Demonstrates SQL injection through string concatenation
- **Pattern**: `$"SELECT * FROM Products WHERE Name LIKE '%{searchTerm}%'"`
- **CodeQL Alert**: CWE-89 - Improper Neutralization of Special Elements used in an SQL Command

#### 1.2 Dynamic Query Building
- **File**: `AppDbContext.cs`
- **Method**: `GetProductsUnsafe()` - Line ~45
- **Issue**: Unsafe dynamic SQL construction
- **Pattern**: String concatenation in SQL WHERE clause
- **CodeQL Alert**: SQL injection vulnerability in unsafe method

---

### 2. **Hardcoded Credentials (CWE-798)**

#### 2.1 Database Connection Strings
- **File**: `Program.cs` - Line ~12
- **Issue**: Hardcoded database password in connection string
- **Pattern**: `"Password=MyPassword123!"`
- **CodeQL Alert**: Hard-coded credentials

#### 2.2 API Keys in Source Code
- **File**: `Program.cs` - SeedDatabase method
- **Lines**: 78, 90, 102, 114, 126, 138
- **Issue**: Hardcoded API keys in seed data
- **Pattern**: `SupplierApiKey = "sk_live_abc123def456ghi789"`
- **CodeQL Alert**: Hard-coded credentials in source code

#### 2.3 API Keys in Model Data
- **File**: `Models/Product.cs`
- **Property**: `SupplierApiKey`
- **Issue**: Storing API keys in plain text
- **CodeQL Alert**: Sensitive data exposure

---

### 3. **XML External Entity (XXE) Injection (CWE-611)**

#### 3.1 Unsafe XML Processing
- **File**: `ProductsController.cs`
- **Method**: `ImportProductsFromXml()` - Line ~235
- **Issue**: XMLDocument without DTD protection
- **Pattern**: `xmlDoc.LoadXml(xmlContent)`
- **CodeQL Alert**: XML external entity vulnerability

---

### 4. **Path Traversal (CWE-22)**

#### 4.1 Unsafe File Operations
- **File**: `ProductsController.cs`
- **Method**: `UploadCatalog()` - Line ~200
- **Issue**: Unvalidated file path construction
- **Pattern**: `Path.Combine("uploads", fileName)`
- **CodeQL Alert**: Path traversal vulnerability

---

### 5. **Command Injection (CWE-78)**

#### 5.1 Unsafe Process Execution
- **File**: `ProductsController.cs`
- **Method**: `BackupDatabase()` - Line ~270
- **Issue**: User input directly in system commands
- **Pattern**: `$"/c sqlcmd -S localhost -E -Q \"BACKUP DATABASE ProductsDB TO DISK = '{backupPath}'\""`
- **CodeQL Alert**: Command injection vulnerability

---

### 6. **Information Disclosure (CWE-200)**

#### 6.1 Detailed Exception Exposure
- **Files**: Multiple locations in `ProductsController.cs`
- **Methods**: 
  - `GetProducts()` - Exception handler
  - `SearchProducts()` - Exception handler
  - `AdvancedSearch()` - Exception handler
  - `ImportProductsFromXml()` - Exception handler
- **Issue**: Stack traces and internal details exposed to clients
- **Pattern**: `return BadRequest(new { Error = ex.Message, StackTrace = ex.StackTrace })`
- **CodeQL Alert**: Information exposure through error messages

#### 6.2 Developer Exception Page in Production
- **File**: `Program.cs` - Line ~48
- **Issue**: Developer exception page enabled in production
- **Pattern**: `app.UseDeveloperExceptionPage()`
- **CodeQL Alert**: Sensitive information disclosure

---

### 7. **Weak Random Number Generation (CWE-338)**

#### 7.1 Insecure Random for Security Tokens
- **File**: `ProductsController.cs`
- **Method**: `GenerateWeakApiKey()` - Line ~310
- **Issue**: Using System.Random for security-sensitive operations
- **Pattern**: `var random = new Random(); random.NextBytes(keyBytes);`
- **CodeQL Alert**: Weak random number generator

---

### 8. **Missing Authorization (CWE-862)**

#### 8.1 Unprotected Administrative Functions
- **File**: `ProductsController.cs`
- **Methods**:
  - `DeleteProduct()` - Line ~175 (no [Authorize] attribute)
  - `DeleteAllProducts()` - Line ~185 (admin function without auth)
  - `BackupDatabase()` - Line ~270 (sensitive operation)
- **Issue**: Critical operations accessible without authentication
- **CodeQL Alert**: Missing authorization

#### 8.2 Missing Authentication Middleware
- **File**: `Program.cs` - Lines ~42-43
- **Issue**: Authentication and authorization middleware commented out
- **Pattern**: `// app.UseAuthentication(); // app.UseAuthorization();`
- **CodeQL Alert**: Missing security middleware

---

### 9. **Insecure Direct Object Reference (CWE-639)**

#### 9.1 Unauthorized Data Access
- **File**: `ProductsController.cs`
- **Method**: `GetUserProducts()` - Line ~315
- **Issue**: Any user can access any user's products
- **Pattern**: No authorization check on userId parameter
- **CodeQL Alert**: Insecure direct object reference

---

### 10. **Resource Leaks (CWE-404)**

#### 10.1 Undisposed Database Connections
- **File**: `AppDbContext.cs`
- **Method**: `GetProductsUnsafe()` - Line ~45
- **Issue**: Database connection opened but never closed
- **Pattern**: `connection.Open()` without using statement or dispose
- **CodeQL Alert**: Resource leak

#### 10.2 File Handle Leaks
- **File**: `ProductsController.cs`
- **Method**: `LegacySearch()` - Line ~330 (commented pattern)
- **Issue**: Shows pattern of resource not being disposed
- **CodeQL Alert**: Resource management issue

---

### 11. **Insecure CORS Configuration (CWE-942)**

#### 11.1 Overly Permissive Cross-Origin Policy
- **File**: `Program.cs` - Lines ~18-24
- **Issue**: Allows any origin, method, and header
- **Pattern**: `AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()`
- **CodeQL Alert**: Insecure CORS configuration

---

### 12. **Missing HTTPS Enforcement (CWE-319)**

#### 12.1 HTTP Traffic Allowed
- **File**: `Program.cs` - Line ~39
- **Issue**: HTTPS redirection disabled
- **Pattern**: `// app.UseHttpsRedirection();`
- **CodeQL Alert**: Missing secure transport

---

### 13. **Vulnerable Dependencies (CWE-1035)**

#### 13.1 Known Vulnerable Package
- **File**: `ProductWebApi.csproj` - Line ~12
- **Package**: `System.Data.SqlClient` version 4.8.5
- **Issue**: Package has known high severity vulnerability
- **CVE**: GHSA-98g6-xh36-x2p7
- **CodeQL Alert**: Use of vulnerable dependency

---

### 14. **Weak Cryptography (CWE-326)**

#### 14.1 Insecure Random Generation
- **File**: `ProductsController.cs`
- **Method**: `GenerateWeakApiKey()`
- **Issue**: Non-cryptographic random number generator
- **Pattern**: Using `System.Random` instead of `System.Security.Cryptography.RandomNumberGenerator`
- **CodeQL Alert**: Use of weak cryptographic algorithm

---

### 15. **Sensitive Data in Logs (CWE-532)**

#### 15.1 Internal Notes Exposure
- **File**: `Models/Product.cs`
- **Property**: `InternalNotes`
- **Issue**: Sensitive business information in API responses
- **Pattern**: Returning internal notes to clients
- **CodeQL Alert**: Sensitive information exposure

---

## 🎯 Demo Script Recommendations

### Phase 1: Show Working Application
1. Navigate to `http://localhost:5000/swagger`
2. Test basic CRUD operations
3. Show that application works normally

### Phase 2: Enable CodeQL Scanning
1. Initialize GitHub repository
2. Enable GitHub Advanced Security
3. Configure CodeQL workflow
4. Push code to trigger scan

### Phase 3: Review Security Alerts
Use this checklist to verify CodeQL detects:
- [ ] SQL Injection vulnerabilities (3+ alerts)
- [ ] Hardcoded credentials (6+ alerts)
- [ ] XXE injection (1 alert)
- [ ] Path traversal (1 alert)
- [ ] Command injection (1 alert)
- [ ] Information disclosure (4+ alerts)
- [ ] Weak cryptography (1 alert)
- [ ] Missing authorization (3+ alerts)
- [ ] Insecure CORS (1 alert)
- [ ] Vulnerable dependencies (1 alert)

### Phase 4: Demonstrate Impact
1. Show how each vulnerability could be exploited
2. Explain the business risk
3. Discuss remediation strategies

---

## 📊 Expected CodeQL Results Summary

| Category | Severity | Count | Examples |
|----------|----------|-------|----------|
| Injection | High | 4 | SQL Injection, XXE, Command Injection |
| Authentication | High | 3 | Missing auth, hardcoded credentials |
| Sensitive Data | Medium | 5 | Information disclosure, logs |
| Configuration | Medium | 3 | CORS, HTTPS, exception handling |
| Dependencies | High | 1 | Vulnerable package |
| **Total** | **Mixed** | **16+** | **Multiple vulnerability types** |

## 🔧 Key Demo Points

1. **Realistic Vulnerabilities**: All issues are based on real-world patterns
2. **Multiple Categories**: Covers OWASP Top 10 and common security issues
3. **Working Code**: Application functions normally despite vulnerabilities
4. **Educational Value**: Each issue includes explanation and secure alternatives
5. **Comprehensive Coverage**: Shows breadth of static analysis capabilities

This checklist ensures your CodeQL demonstration covers a comprehensive range of security vulnerabilities that junior developers commonly encounter.