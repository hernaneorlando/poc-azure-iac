namespace POC.Models;

public record Customer
{
    public int CustomerId { get; init; }
    public string? CustomerName { get; set; }
    public string? Email { get; set; }
    public string? PhoneNumber { get; set; }
}
