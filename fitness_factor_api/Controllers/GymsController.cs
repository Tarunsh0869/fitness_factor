using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using fitness_factor_api.Data;
using fitness_factor_api.DTOs;

namespace fitness_factor_api.Controllers;

[ApiController]
[Route("api/gyms")]
[Authorize]
public class GymsController(AppDbContext db) : ControllerBase
{
    // GET api/gyms/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetGym(int id)
    {
        var gym = await db.Gyms.FindAsync(id);
        if (gym is null) return NotFound();

        return Ok(new GymDto(
            gym.Id, gym.Name, gym.Latitude, gym.Longitude, gym.RadiusMeters));
    }
}
