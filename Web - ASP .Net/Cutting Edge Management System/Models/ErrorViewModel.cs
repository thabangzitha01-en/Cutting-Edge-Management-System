namespace CuttingEdge.ManagerPortal.Models;
/// Backing model for the shared error page. Exposes the request ID
/// so support can correlate the error with server logs.
public class ErrorViewModel
{
    // ASP.NET Core trace/request ID for correlating with logs.
    public string? RequestId { get; set; }

    // Only show the request ID when one was actually captured.
    public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
}
