namespace CuttingEdge.ManagerPortal.Models;
// A salon service offering (public.services).

public class Service
{
    public long ServiceId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public int DurationMinutes { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsFlagship { get; set; }
    public bool Active { get; set; } = true;
    public DateTime CreatedAt { get; set; }
}
