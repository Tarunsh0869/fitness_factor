using System.ComponentModel.DataAnnotations;

namespace fitness_factor_api.Entities;

public class Gym
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public decimal Latitude { get; set; }

    [Required]
    public decimal Longitude { get; set; }

    public int RadiusMeters { get; set; } = 50;

    public ICollection<Attendance> Attendances { get; set; } = [];
}
