using System.Net;

namespace POC.Models;

public record ApiResponse
{
    public HttpStatusCode StatusCode { get; init; }
    public string Message { get; init; } = string.Empty;
    public object Data { get; init; } = new();
}
