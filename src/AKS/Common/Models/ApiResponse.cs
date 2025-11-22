namespace Common.Models;

public record ApiResponse
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
    public object Data { get; init; } = new();
}
