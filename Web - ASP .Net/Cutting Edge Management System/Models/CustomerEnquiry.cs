namespace CuttingEdge.ManagerPortal.Models;
// Stored in public.customer_enquiries (shared with the Flutter customer app).
/// A customer message (support, feedback, or stylist leave request) that
/// managers can read and reply to.
public sealed class CustomerEnquiry
{
    public long EnquiryId { get; set; }
    public Guid CustomerId { get; set; }
    public string Category { get; set; } = "";
    public string Subject { get; set; } = "";
    public string Message { get; set; } = "";
    public string Status { get; set; } = "open";
    public string? ManagerReply { get; set; }
    public Guid? RepliedBy { get; set; }
    public DateTimeOffset? RepliedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }


    // View-only fields populated from public.profiles; not database columns.
    // Display name of the customer, defaulted for safety.
    public string CustomerName { get; set; } = "Customer";
    public string CustomerEmail { get; set; } = "";
}
