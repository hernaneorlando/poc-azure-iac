using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using POC.Models;

namespace POC.SupplierFunction;

public class SupplierFunction(ILogger<SupplierFunction> logger)
{
    private static readonly List<Supplier> suppliers =
        [
            new() {
                SupplierId = 1,
                SupplierName = "ABC Supplies",
                ContactEmail = "contact@abcsupplies.com"
            },
            new() {
                SupplierId = 2,
                SupplierName = "XYZ Corp",
                ContactEmail = "info@xyzcorp.com" 
            },
            new() {
                SupplierId = 3,
                SupplierName = "Global Trade Inc",
                ContactEmail = "sales@globaltrade.com" 
            }
        ];

    [Function("GetAllSuppliers")]
    public IActionResult GetAllSuppliers([HttpTrigger(AuthorizationLevel.Function, "get", Route = "supplier")] HttpRequest req)
    {
        logger.LogInformation("C# HTTP trigger function processed a GET request for all suppliers.");

        var result = new ApiResponse
        {
            StatusCode = HttpStatusCode.OK,
            Message = "Suppliers retrieved successfully.",
            Data = suppliers
        };

        return new OkObjectResult(result);
    }

    [Function("GetSupplierById")]
    public IActionResult GetSupplierById(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "supplier/{id}")] HttpRequest req,
        int id)
    {
        logger.LogInformation("C# HTTP trigger function processed a GET request for supplier {SupplierId}.", id);

        var supplier = suppliers.FirstOrDefault(s => s.SupplierId == id);
        if (supplier == null)  
        {
            logger.LogWarning("Supplier not found with ID: {SupplierId}", id);
            return new NotFoundObjectResult(new ApiResponse
            {
                StatusCode = HttpStatusCode.NotFound,
                Message = $"Supplier with ID {id} not found."
            });
        }

        var result = new ApiResponse
        {
            StatusCode = HttpStatusCode.OK,
            Message = $"Supplier {id} retrieved successfully.",
            Data = supplier
        };

        return new OkObjectResult(result);
    }

    [Function("CreateSupplier")]
    public async Task<IActionResult> RunCreate([HttpTrigger(AuthorizationLevel.Function, "post", Route = "supplier")] HttpRequest req)
    {
        logger.LogInformation("C# HTTP trigger function processed a POST request to create a supplier.");

        Supplier? supplier;
        try
        {
            supplier = await req.ReadFromJsonAsync<Supplier>();
            if (supplier == null)
            {
                logger.LogWarning("Invalid supplier object in request body.");
                return new BadRequestObjectResult(new ApiResponse
                {
                    StatusCode = HttpStatusCode.BadRequest,
                    Message = "Invalid request body. Please provide a valid Supplier object."
                });
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error parsing request body");
            return new BadRequestObjectResult(new ApiResponse
            {
                StatusCode = HttpStatusCode.BadRequest,
                Message = $"Error parsing request body: {ex.Message}"
            });
        }

        // Simulate supplier creation (here you would save to database)
        var newSupplierId = new Random().Next(1000, 9999); 

        var result = new ApiResponse
        {
            StatusCode = HttpStatusCode.Created,
            Message = "Supplier created successfully.",
            Data = supplier 
        };

        return new CreatedResult($"{req.Scheme}://{req.Host}/function/supplier/{newSupplierId}", result);
    }
}