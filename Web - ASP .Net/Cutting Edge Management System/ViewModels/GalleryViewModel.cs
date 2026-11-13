using CuttingEdge.ManagerPortal.Models;

namespace CuttingEdge.ManagerPortal.ViewModels;
// Backs the Gallery management page: the list of images plus the editable
// About Us copy shown on the public site.

public class GalleryViewModel
{
    // Images rendered in the gallery grid.
    public List<GalleryImage> Images { get; set; } = new();
    public string AboutUs { get; set; } = string.Empty; // Editable "About Us" text; defaults to empty so the view can render safely.
}
