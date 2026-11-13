using CuttingEdge.ManagerPortal.Models;

namespace CuttingEdge.ManagerPortal.ViewModels;
// Backs the Services & Promotions management page, showing both lists on one screen.

public class ServicesPromotionsViewModel
{
    public List<Service> Services { get; set; } = new(); // All available services.
    public List<Promotion> Promotions { get; set; } = new(); // All promotions (active and inactive).
}
