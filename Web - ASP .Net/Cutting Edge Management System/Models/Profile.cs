namespace CuttingEdge.ManagerPortal.Models;
// Application user profile (public.profiles), covering managers,
// stylists, and customers. Role determines portal access.

public class Profile
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = "Customer";
    public string? PhotoUrl { get; set; }
    public string? Branch { get; set; }
    public DateTime CreatedAt { get; set; }
}
