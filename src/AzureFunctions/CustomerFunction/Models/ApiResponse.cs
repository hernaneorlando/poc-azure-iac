using System.Net;

namespace POC.Models;

public class ApiResponse
{
    public HttpStatusCode StatusCode { get; set; }
    public string? Message { get; set; }
    public object? Data { get; set; }
}
