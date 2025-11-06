using System.ComponentModel.DataAnnotations;

namespace ProductWebApi.Models
{
    public class Product
    {
        public int Id { get; set; }
        
        [Required]
        public string Name { get; set; } = string.Empty;
        
        public string Description { get; set; } = string.Empty;
        
        [Required]
        public decimal Price { get; set; }
        
        public int CategoryId { get; set; }
        
        public DateTime CreatedDate { get; set; } = DateTime.Now;
        
        public string CreatedBy { get; set; } = string.Empty;
        
        // VULNERABLE: Storing sensitive data in plain text
        public string InternalNotes { get; set; } = string.Empty;
        
        // VULNERABLE: Storing API keys or secrets
        public string SupplierApiKey { get; set; } = string.Empty;
    }
    
    public class ProductSearchRequest
    {
        public string? SearchTerm { get; set; }
        public string? CategoryFilter { get; set; }
        public string? SortBy { get; set; }
        public string? SortOrder { get; set; }
    }
    
    public class ProductCreateRequest
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        
        public string Description { get; set; } = string.Empty;
        
        [Required]
        public decimal Price { get; set; }
        
        public int CategoryId { get; set; }
        
        public string CreatedBy { get; set; } = string.Empty;
        
        public string InternalNotes { get; set; } = string.Empty;
    }
}