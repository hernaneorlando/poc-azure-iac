using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using POC.Models;

namespace POC.CustomerFunction;

public class CustomerFunction(ILogger<CustomerFunction> logger)
{
    private static readonly List<Customer> customers =
        [
            new() { 
                CustomerId = 1, 
                CustomerName = "John Doe", 
                Email = "john.doe@email.com",
                PhoneNumber = "+1-555-0101"
            },
            new() { 
                CustomerId = 2, 
                CustomerName = "Jane Smith", 
                Email = "jane.smith@email.com",
                PhoneNumber = "+1-555-0102"
            },
            new() { 
                CustomerId = 3, 
                CustomerName = "Bob Johnson", 
                Email = "bob.johnson@email.com",
                PhoneNumber = "+1-555-0103"
            }
        ];

    [Function("GetAllCustomers")]
    public IActionResult GetAllCustomers([HttpTrigger(AuthorizationLevel.Function, "get", Route = "customer")] HttpRequest req)
    {
        logger.LogInformation("C# HTTP trigger function processed a GET request for all customers.");

        var result = new ApiResponse
        {
            StatusCode = HttpStatusCode.OK,
            Message = "Customers retrieved successfully.",
            Data = customers
        };

        return new OkObjectResult(result);
    }

    [Function("GetCustomerById")]
    public IActionResult GetCustomerById(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "customer/{id}")] HttpRequest req,
        int id)
    {
        logger.LogInformation("C# HTTP trigger function processed a GET request for customer {CustomerId}.", id);

        var customer = customers.FirstOrDefault(c => c.CustomerId == id);
        if (customer == null)
        {
            logger.LogWarning("Customer not found with ID: {CustomerId}", id);
            return new NotFoundObjectResult(new ApiResponse
            {
                StatusCode = HttpStatusCode.NotFound,
                Message = $"Customer with ID {id} not found."
            });
        }

        var result = new ApiResponse
        {
            StatusCode = HttpStatusCode.OK,
            Message = $"Customer {id} retrieved successfully.",
            Data = customer
        };

        return new OkObjectResult(result);
    }

    [Function("CreateCustomer")]
    public async Task<IActionResult> CreateCustomer([HttpTrigger(AuthorizationLevel.Function, "post", Route = "customer")] HttpRequest req)
    {
        logger.LogInformation("C# HTTP trigger function processed a POST request to create a customer.");
        
        Customer? customer;
        try
        {
            customer = await req.ReadFromJsonAsync<Customer>();
            if (customer == null)
            {
                logger.LogWarning("Invalid customer object in request body.");
                return new BadRequestObjectResult(new ApiResponse
                {
                    StatusCode = HttpStatusCode.BadRequest,
                    Message = "Invalid request body. Please provide a valid Customer object."
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
        
        // Simulate customer creation (would normally save to database)
        var newCustomerId = new Random().Next(1000, 9999);
        
        var result = new ApiResponse
        {
            StatusCode = HttpStatusCode.Created,
            Message = "Customer created successfully.",
            Data = customer with { CustomerId = newCustomerId }
        };

        return new CreatedResult($"{req.Scheme}://{req.Host}/api/customer/{newCustomerId}", result);
    }
}
