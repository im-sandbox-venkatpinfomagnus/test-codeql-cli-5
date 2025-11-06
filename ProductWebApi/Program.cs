using Microsoft.EntityFrameworkCore;
using ProductWebApi.Data;
using ProductWebApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// VULNERABLE: Using hardcoded connection string with credentials (kept for demo purposes)
var connectionString = "Server=localhost;Database=ProductsDB;User Id=sa;Password=MyPassword123!;TrustServerCertificate=true;";

// Use in-memory database for demo purposes
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseInMemoryDatabase("ProductsDB"));

// VULNERABLE: Overly permissive CORS policy
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Initialize the database with seed data
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    SeedDatabase(context);
}

// Configure the HTTP request pipeline.
// VULNERABLE: Enabling Swagger in production
app.UseSwagger();
app.UseSwaggerUI();

if (app.Environment.IsDevelopment())
{
    // Additional dev-only configurations can go here
}

// VULNERABLE: Missing HTTPS redirection
// app.UseHttpsRedirection();

app.UseCors();

// VULNERABLE: Missing authentication and authorization
// app.UseAuthentication();
// app.UseAuthorization();

app.MapControllers();

// VULNERABLE: Detailed error information exposed
app.UseDeveloperExceptionPage();

// Add a default route that redirects to Swagger
app.MapGet("/", () => Results.Redirect("/swagger"));

app.Run();

// Method to seed the database with initial data
static void SeedDatabase(AppDbContext context)
{
    // Clear existing data
    context.Products.RemoveRange(context.Products);
    
    // Add seed data
    var products = new List<Product>
    {
        new Product
        {
            Id = 1,
            Name = "Laptop Pro 15\"",
            Description = "High-performance laptop with 16GB RAM and 512GB SSD",
            Price = 1299.99m,
            CategoryId = 1,
            CreatedDate = DateTime.Now.AddDays(-30),
            CreatedBy = "admin",
            InternalNotes = "Supplier: TechCorp Inc, Cost: $1000, Margin: 23%",
            SupplierApiKey = "sk_live_abc123def456ghi789" // VULNERABLE: Hardcoded API key
        },
        new Product
        {
            Id = 2,
            Name = "Wireless Mouse",
            Description = "Ergonomic wireless optical mouse with 3-year warranty",
            Price = 29.99m,
            CategoryId = 2,
            CreatedDate = DateTime.Now.AddDays(-25),
            CreatedBy = "admin",
            InternalNotes = "Bulk discount available for 100+ units",
            SupplierApiKey = "sk_test_xyz789abc012def345" // VULNERABLE: Hardcoded API key
        },
        new Product
        {
            Id = 3,
            Name = "4K Monitor",
            Description = "27-inch 4K UHD monitor with HDR support",
            Price = 399.99m,
            CategoryId = 1,
            CreatedDate = DateTime.Now.AddDays(-20),
            CreatedBy = "manager",
            InternalNotes = "Popular item - reorder when stock < 10",
            SupplierApiKey = "sk_live_monitor_secret_key" // VULNERABLE: Hardcoded API key
        },
        new Product
        {
            Id = 4,
            Name = "Mechanical Keyboard",
            Description = "RGB backlit mechanical keyboard with Cherry MX switches",
            Price = 129.99m,
            CategoryId = 2,
            CreatedDate = DateTime.Now.AddDays(-15),
            CreatedBy = "admin",
            InternalNotes = "Premium product with high margin",
            SupplierApiKey = "sk_kb_api_key_2024" // VULNERABLE: Hardcoded API key
        },
        new Product
        {
            Id = 5,
            Name = "USB-C Hub",
            Description = "7-in-1 USB-C hub with HDMI, USB 3.0, and card readers",
            Price = 49.99m,
            CategoryId = 3,
            CreatedDate = DateTime.Now.AddDays(-10),
            CreatedBy = "staff",
            InternalNotes = "Fast moving accessory item",
            SupplierApiKey = "hub_supplier_secret_2024" // VULNERABLE: Hardcoded API key
        },
        new Product
        {
            Id = 6,
            Name = "Webcam HD",
            Description = "1080p HD webcam with built-in microphone",
            Price = 79.99m,
            CategoryId = 3,
            CreatedDate = DateTime.Now.AddDays(-5),
            CreatedBy = "admin",
            InternalNotes = "High demand since remote work trend",
            SupplierApiKey = "webcam_api_secret_key" // VULNERABLE: Hardcoded API key
        }
    };

    context.Products.AddRange(products);
    context.SaveChanges();
}