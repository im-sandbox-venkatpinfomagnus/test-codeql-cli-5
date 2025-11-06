using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProductWebApi.Data;
using ProductWebApi.Models;
using System.Data.SqlClient;
using System.Text;
using System.Xml;
using System.Diagnostics;

namespace ProductWebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProductsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/products
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
        {
            try
            {
                return await _context.Products.ToListAsync();
            }
            catch (Exception ex)
            {
                // VULNERABLE: Exposing detailed error information
                return BadRequest(new { 
                    Error = ex.Message, 
                    StackTrace = ex.StackTrace,
                    InnerException = ex.InnerException?.Message 
                });
            }
        }

        // GET: api/products/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Product>> GetProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);

            if (product == null)
            {
                return NotFound();
            }

            return product;
        }

        // VULNERABLE: SQL Injection in search endpoint
        [HttpGet("search/{searchTerm}")]
        public async Task<IActionResult> SearchProducts(string searchTerm)
        {
            try
            {
                // VULNERABLE: This would be SQL injection in real SQL Server scenario
                // Using LINQ for demo purposes but showing vulnerable pattern
                var products = await _context.Products
                    .Where(p => p.Name.Contains(searchTerm) || p.Description.Contains(searchTerm))
                    .ToListAsync();
                
                return Ok(products);
            }
            catch (Exception ex)
            {
                // VULNERABLE: Exposing detailed error information
                return BadRequest(new { 
                    Error = ex.Message, 
                    StackTrace = ex.StackTrace 
                });
            }
        }

        // VULNERABLE: Advanced search with multiple SQL injection points
        [HttpPost("advanced-search")]
        public async Task<IActionResult> AdvancedSearch([FromBody] ProductSearchRequest request)
        {
            try
            {
                // VULNERABLE: In a real scenario, this would build dynamic SQL with injection risks
                // Using LINQ for demo but showing the vulnerable pattern in comments
                
                var query = _context.Products.AsQueryable();
                
                if (!string.IsNullOrEmpty(request.SearchTerm))
                {
                    // VULNERABLE PATTERN: var sql = $"... WHERE Name LIKE '%{request.SearchTerm}%'"
                    query = query.Where(p => p.Name.Contains(request.SearchTerm) || 
                                           p.Description.Contains(request.SearchTerm));
                }
                
                if (!string.IsNullOrEmpty(request.CategoryFilter))
                {
                    // VULNERABLE PATTERN: var sql = $"... AND CategoryId = {request.CategoryFilter}"
                    if (int.TryParse(request.CategoryFilter, out int categoryId))
                    {
                        query = query.Where(p => p.CategoryId == categoryId);
                    }
                }
                
                // VULNERABLE PATTERN: Dynamic ORDER BY would be: $"ORDER BY {request.SortBy} {request.SortOrder}"
                if (!string.IsNullOrEmpty(request.SortBy))
                {
                    switch (request.SortBy.ToLower())
                    {
                        case "name":
                            query = request.SortOrder?.ToLower() == "desc" ? 
                                query.OrderByDescending(p => p.Name) : query.OrderBy(p => p.Name);
                            break;
                        case "price":
                            query = request.SortOrder?.ToLower() == "desc" ? 
                                query.OrderByDescending(p => p.Price) : query.OrderBy(p => p.Price);
                            break;
                        default:
                            query = query.OrderBy(p => p.Id);
                            break;
                    }
                }

                var products = await query.ToListAsync();
                return Ok(products);
            }
            catch (Exception ex)
            {
                // VULNERABLE: Exposing detailed error information
                return BadRequest(new { 
                    Error = ex.Message, 
                    StackTrace = ex.StackTrace 
                });
            }
        }

        // POST: api/products
        [HttpPost]
        public async Task<ActionResult<Product>> CreateProduct(ProductCreateRequest request)
        {
            var product = new Product
            {
                Name = request.Name,
                Description = request.Description,
                Price = request.Price,
                CategoryId = request.CategoryId,
                CreatedBy = request.CreatedBy,
                InternalNotes = request.InternalNotes,
                CreatedDate = DateTime.Now,
                // VULNERABLE: Generating weak API key
                SupplierApiKey = GenerateWeakApiKey()
            };

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
        }

        // PUT: api/products/5
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, Product product)
        {
            if (id != product.Id)
            {
                return BadRequest();
            }

            _context.Entry(product).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ProductExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // DELETE: api/products/5
        // VULNERABLE: Missing authorization for sensitive operation
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null)
            {
                return NotFound();
            }

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // VULNERABLE: Administrative function without authorization
        [HttpDelete("admin/delete-all")]
        public async Task<IActionResult> DeleteAllProducts()
        {
            var products = await _context.Products.ToListAsync();
            _context.Products.RemoveRange(products);
            await _context.SaveChangesAsync();
            
            return Ok(new { Message = $"Deleted {products.Count} products" });
        }

        // VULNERABLE: File upload with path traversal vulnerability
        [HttpPost("upload-catalog")]
        public async Task<IActionResult> UploadCatalog(IFormFile file, string fileName)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded");

            // VULNERABLE: No path validation allows directory traversal
            var filePath = Path.Combine("uploads", fileName);
            
            using var stream = new FileStream(filePath, FileMode.Create);
            await file.CopyToAsync(stream);
            
            return Ok(new { Message = "File uploaded successfully", Path = filePath });
        }

        // VULNERABLE: XML parsing without protection against XXE
        [HttpPost("import-xml")]
        public IActionResult ImportProductsFromXml([FromBody] string xmlContent)
        {
            try
            {
                // VULNERABLE: XMLDocument with default settings allows XXE attacks
                var xmlDoc = new XmlDocument();
                xmlDoc.LoadXml(xmlContent);
                
                var products = new List<Product>();
                var productNodes = xmlDoc.SelectNodes("//Product");
                
                if (productNodes != null)
                {
                    foreach (XmlNode node in productNodes)
                    {
                        var product = new Product
                        {
                            Name = node.SelectSingleNode("Name")?.InnerText ?? "",
                            Description = node.SelectSingleNode("Description")?.InnerText ?? "",
                            Price = decimal.Parse(node.SelectSingleNode("Price")?.InnerText ?? "0"),
                            CategoryId = int.Parse(node.SelectSingleNode("CategoryId")?.InnerText ?? "0")
                        };
                        products.Add(product);
                    }
                }
                
                return Ok(new { ImportedCount = products.Count, Products = products });
            }
            catch (Exception ex)
            {
                // VULNERABLE: Exposing detailed exception information
                return BadRequest(new { 
                    Error = ex.Message, 
                    StackTrace = ex.StackTrace 
                });
            }
        }

        // VULNERABLE: Command injection in backup functionality
        [HttpPost("backup")]
        public IActionResult BackupDatabase(string backupPath)
        {
            try
            {
                // VULNERABLE: Direct command execution without validation
                var process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "cmd.exe",
                        Arguments = $"/c sqlcmd -S localhost -E -Q \"BACKUP DATABASE ProductsDB TO DISK = '{backupPath}'\"",
                        RedirectStandardOutput = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };
                
                process.Start();
                var output = process.StandardOutput.ReadToEnd();
                process.WaitForExit();
                
                return Ok(new { Message = "Backup completed", Output = output });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }

        // VULNERABLE: Weak random number generation for API keys
        private string GenerateWeakApiKey()
        {
            var random = new Random();
            var keyBytes = new byte[16];
            random.NextBytes(keyBytes);
            return Convert.ToBase64String(keyBytes);
        }

        // VULNERABLE: Insecure direct object reference
        [HttpGet("user/{userId}/products")]
        public async Task<ActionResult<IEnumerable<Product>>> GetUserProducts(int userId)
        {
            // VULNERABLE: No authorization check - any user can access any user's products
            var products = await _context.Products
                .Where(p => p.CreatedBy == userId.ToString())
                .ToListAsync();
                
            return Ok(products);
        }

        // VULNERABLE: Resource leak pattern - shows poor resource management
        [HttpGet("legacy-search/{term}")]
        public async Task<IActionResult> LegacySearch(string term)
        {
            // VULNERABLE PATTERN: In real scenario with SqlConnection, this would be a resource leak
            // Using EF for demo but showing the vulnerable pattern in comments
            
            // VULNERABLE CODE PATTERN:
            // var connection = new SqlConnection(connectionString);
            // connection.Open();
            // var command = new SqlCommand($"SELECT COUNT(*) FROM Products WHERE Name LIKE '%{term}%'", connection);
            // var count = command.ExecuteScalar();
            // return Ok(new { Count = count });
            // // Connection never closed - resource leak!
            
            var count = await _context.Products.CountAsync(p => p.Name.Contains(term));
            return Ok(new { Count = count });
        }

        private bool ProductExists(int id)
        {
            return _context.Products.Any(e => e.Id == id);
        }
    }
}