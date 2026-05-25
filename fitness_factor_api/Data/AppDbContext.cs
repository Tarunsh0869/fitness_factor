using Microsoft.EntityFrameworkCore;
using fitness_factor_api.Entities;

namespace fitness_factor_api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Member>     Members     => Set<Member>();
    public DbSet<Gym>        Gyms        => Set<Gym>();
    public DbSet<Attendance> Attendances => Set<Attendance>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Unique phone per member
        modelBuilder.Entity<Member>()
            .HasIndex(m => m.Phone)
            .IsUnique();

        modelBuilder.Entity<Member>()
            .Property(m => m.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        modelBuilder.Entity<Gym>()
            .Property(g => g.Latitude)
            .HasColumnType("decimal(10,8)");

        modelBuilder.Entity<Gym>()
            .Property(g => g.Longitude)
            .HasColumnType("decimal(11,8)");

        modelBuilder.Entity<Attendance>()
            .Property(a => a.Source)
            .HasDefaultValue("auto");

        // Fast lookup: open sessions per member
        modelBuilder.Entity<Attendance>()
            .HasIndex(a => new { a.MemberId, a.CheckedOut });

        // Fast history queries
        modelBuilder.Entity<Attendance>()
            .HasIndex(a => new { a.MemberId, a.CheckedIn });

        // Seed gym
        modelBuilder.Entity<Gym>().HasData(
            new Gym
            {
                Id           = 1,
                Name         = "Fitness Factor HQ",
                Latitude     = 3.1390m,
                Longitude    = 101.6869m,
                RadiusMeters = 50
            }
        );
    }
}
