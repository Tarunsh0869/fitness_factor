using System.ComponentModel.DataAnnotations;

namespace fitness_factor_api.DTOs;

// ── Members ───────────────────────────────────────────────────────────────────

public record MemberLoginDto(
    [Required, MaxLength(20)] string Phone
);

public record MemberRegisterDto(
    [Required, MaxLength(100)] string Name,
    [Required, MaxLength(20)]  string Phone
);

public record MemberLoginResponseDto(
    string Token,
    int    MemberId,
    string Name,
    int    GymId
);

public record UpdateFcmTokenDto(
    [Required] string FcmToken
);

// ── Gyms ──────────────────────────────────────────────────────────────────────

public record GymDto(
    int     Id,
    string  Name,
    decimal Latitude,
    decimal Longitude,
    int     RadiusMeters
);

// ── Attendance ────────────────────────────────────────────────────────────────

public record CheckInDto(
    [Required] int MemberId,
    [Required] int GymId
);

public record CheckOutDto(
    [Required] int SessionId
);

public record NotifyExitDto(
    [Required] int MemberId
);

public record AttendanceRecordDto(
    int       Id,
    DateTime  CheckedIn,
    DateTime? CheckedOut,
    string    Source
);
