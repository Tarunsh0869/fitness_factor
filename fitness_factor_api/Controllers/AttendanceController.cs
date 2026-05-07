using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using fitness_factor_api.Data;
using fitness_factor_api.DTOs;
using fitness_factor_api.Entities;
using fitness_factor_api.Services;

namespace fitness_factor_api.Controllers;

[ApiController]
[Route("api/attendance")]
[Authorize]
public class AttendanceController(AppDbContext db, FirebaseService firebase) : ControllerBase
{
    // POST api/attendance/checkin
    [HttpPost("checkin")]
    public async Task<IActionResult> CheckIn(CheckInDto dto)
    {
        // Guard: prevent duplicate open session
        var hasOpen = await db.Attendances
            .AnyAsync(a => a.MemberId == dto.MemberId && a.CheckedOut == null);

        if (hasOpen)
            return Conflict(new { message = "Already checked in." });

        var record = new Attendance
        {
            MemberId  = dto.MemberId,
            GymId     = dto.GymId,
            CheckedIn = DateTime.UtcNow,
            Source    = "auto"
        };

        db.Attendances.Add(record);
        await db.SaveChangesAsync();

        return Ok(new { session_id = record.Id });
    }

    // POST api/attendance/checkout
    [HttpPost("checkout")]
    public async Task<IActionResult> CheckOut(CheckOutDto dto)
    {
        var session = await db.Attendances.FindAsync(dto.SessionId);

        if (session is null || session.CheckedOut != null)
            return NotFound(new { message = "Session not found or already closed." });

        session.CheckedOut = DateTime.UtcNow;
        await db.SaveChangesAsync();

        var durationMin = (int)(session.CheckedOut.Value - session.CheckedIn).TotalMinutes;
        return Ok(new { duration_min = durationMin });
    }

    // POST api/attendance/notify-exit  — Flutter calls this on geofence exit
    [HttpPost("notify-exit")]
    public async Task<IActionResult> NotifyExit(NotifyExitDto dto)
    {
        var member = await db.Members.FindAsync(dto.MemberId);
        if (member is null) return NotFound(new { message = "Member not found." });

        if (string.IsNullOrEmpty(member.FcmToken))
            return BadRequest(new { message = "No FCM token registered for this member." });

        var openSession = await db.Attendances
            .FirstOrDefaultAsync(a => a.MemberId == dto.MemberId && a.CheckedOut == null);

        if (openSession is null)
            return NotFound(new { message = "No open session found." });

        await firebase.SendExitConfirmationAsync(member.FcmToken, openSession.Id);
        return Ok(new { message = "Exit notification sent." });
    }

    // GET api/attendance/history/{memberId}
    [HttpGet("history/{memberId}")]
    public async Task<IActionResult> History(int memberId)
    {
        var records = await db.Attendances
            .Where(a => a.MemberId == memberId)
            .OrderByDescending(a => a.CheckedIn)
            .Take(30)
            .Select(a => new AttendanceRecordDto(
                a.Id, a.CheckedIn, a.CheckedOut, a.Source))
            .ToListAsync();

        return Ok(records);
    }
}
