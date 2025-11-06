using Microsoft.EntityFrameworkCore;
using ProductWebApi.Models;

namespace ProductWebApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<Product> Products { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            // Seed data is now handled in Program.cs for in-memory database
        }

        // VULNERABLE: Method that doesn't dispose resources properly
        public List<Product> GetProductsUnsafe(string searchTerm)
        {
            var connection = Database.GetDbConnection();
            connection.Open();
            
            // This connection is never properly closed - resource leak
            using var command = connection.CreateCommand();
            command.CommandText = $"SELECT * FROM Products WHERE Name LIKE '%{searchTerm}%'"; // SQL Injection
            
            var products = new List<Product>();
            using var reader = command.ExecuteReader();
            
            while (reader.Read())
            {
                products.Add(new Product
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1),
                    Description = reader.GetString(2),
                    Price = reader.GetDecimal(3),
                    CategoryId = reader.GetInt32(4)
                });
            }
            
            return products;
            // Connection never closed!
        }
    }
}