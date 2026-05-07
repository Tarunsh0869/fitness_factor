using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using fitness_factor_api.Data;
using fitness_factor_api.DTOs;
using fitness_factor_api.Entities;
using fitness_factor_api.Services;

namespace fitness_factor_api.Controllers;

[ApiController]
[Route("api/members")]
public class MembersController(AppDbContext db, JwtService jwt) : ControllerBase
{
    // POST api/members/register  (admin creates member)
    [HttpPost("register")]
    public async Task<IActionResult> Register(MemberRegisterDto dto)
    {
        if (await db.Members.AnyAsync(m => m.Phone == dto.Phone))
            return Conflict(new { message = "Phone already registered." });

        var member = new Member { Name = dto.Name, Phone = dto.Phone };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        // Default gym is 1 — adjust if multi-gym
        return Ok(new MemberLoginResponseDto(
            jwt.GenerateToken(member), member.Id, member.Name, GymId: 1));
    }

    // POST api/members/login  (Flutter calls this on app start)
    [HttpPost("login")]
    public async Task<IActionResult> Login(MemberLoginDto dto)
    {
        var member = await db.Members.FirstOrDefaultAsync(m => m.Phone == dto.Phone);
        if (member is null)
            return Unauthorized(new { message = "Phone number not found." });

        return Ok(new MemberLoginResponseDto(
            jwt.GenerateToken(member), member.Id, member.Name, GymId: 1));
    }

    // PATCH api/members/{id}/fcm-token  (Flutter updates after Firebase init)
    [HttpPatch("{id}/fcm-token")]
    [Authorize]
    public async Task<IActionResult> UpdateFcmToken(int id, UpdateFcmTokenDto dto)
    {
        var member = await db.Members.FindAsync(id);
        if (member is null) return NotFound();

        member.FcmToken = dto.FcmToken;
        await db.SaveChangesAsync();
        return NoContent();
    }
}
