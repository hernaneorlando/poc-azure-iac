using Common.Models;
using Microsoft.AspNetCore.Mvc;

namespace Products.Resources;

[ApiController]
[Route("api/[controller]")]
public class ProductsController(ILogger<ProductsController> logger) : ControllerBase
{
    private static readonly List<Product> products =
        [
            new Product { Id = 1, Name = "Product 1", Price = 10.0 },
            new Product { Id = 2, Name = "Product 2", Price = 20.0 },
            new Product { Id = 3, Name = "Product 3", Price = 30.0 }
        ];

    [HttpGet("{id}")]
    public ActionResult<ApiResponse> GetProductById(int id)
    {
        var product = products.FirstOrDefault(p => p.Id == id);
        if (product == null)
        {
            logger.LogWarning("Product not found with ID: {ProductId}", id);
            return NotFound(new ApiResponse { Success = false, Message = "Product not found" });
        }

        return Ok(new ApiResponse { Success = true, Data = product });
    }

    [HttpGet]
    public ActionResult<ApiResponse> GetAllProducts()
    {
        logger.LogInformation("Retrieving all products");
        return Ok(new ApiResponse { Success = true, Data = products });
    }
}

public record Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public double Price { get; set; }
}