using System.ComponentModel.DataAnnotations;

namespace fitness_factor_api.Entities;

public class Attendance
{
    public int Id { get; set; }

    public int MemberId { get; set; }
    public Member Member { get; set; } = null!;

    public int GymId { get; set; }
    public Gym Gym { get; set; } = null!;

    [Required]
    public DateTime CheckedIn { get; set; }

    public DateTime? CheckedOut { get; set; }

    [MaxLength(10)]
    public string Source { get; set; } = "auto";
}
