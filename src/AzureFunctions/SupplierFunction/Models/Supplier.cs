namespace POC.Models;

public record Supplier
{
    public int? SupplierId { get; init; }
    public string SupplierName { get; init; } = string.Empty;
    public string ContactEmail { get; init; } = string.Empty;
}
