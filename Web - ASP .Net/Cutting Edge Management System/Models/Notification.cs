namespace CuttingEdge.ManagerPortal.Models;

/// An in-app notification for a profile (public.notifications).

public class Notification
{
    // Primary key.
    public long NotificationId { get; set; }
    public Guid ProfileId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? NotificationType { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }


    // Navigation property populated by the service layer.
    public Profile? Profile { get; set; }
}
