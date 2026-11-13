namespace CuttingEdge.ManagerPortal.Models;

// Lookup table of accepted payment methods (public.payment_methods).
public class PaymentMethod
{
    // Primary key.
    public long PaymentMethodId { get; set; }
    // Display name, e.g. "Cash", "Card", "EFT".
    public string MethodName { get; set; } = string.Empty;
}
