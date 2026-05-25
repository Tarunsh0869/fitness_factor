using System.Text;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using fitness_factor_api.Data;
using fitness_factor_api.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Database ──────────────────────────────────────────────────────────────────
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ── JWT Authentication ────────────────────────────────────────────────────────
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = builder.Configuration["Jwt:Issuer"],
            ValidAudience            = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey         = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddScoped<JwtService>();
builder.Services.AddSingleton<FirebaseService>();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ── CORS — allow Flutter (Android emulator: 10.0.2.2, device: your IP) ────────
builder.Services.AddCors(opt =>
    opt.AddDefaultPolicy(p =>
        p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

builder.WebHost.UseUrls("http://0.0.0.0:5001");

var app = builder.Build();

// ── Firebase Admin SDK ────────────────────────────────────────────────────────
var serviceAccountPath = builder.Configuration["Firebase:ServiceAccountPath"]!;
if (File.Exists(serviceAccountPath))
{
    FirebaseApp.Create(new AppOptions
    {
        Credential = GoogleCredential.FromFile(serviceAccountPath)
    });
}
else
{
    Console.WriteLine($"[WARNING] Firebase service account not found at: {serviceAccountPath}");
}

// ── Auto-migrate on startup ───────────────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    EnsureLocalSchema(db);
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

static void EnsureLocalSchema(AppDbContext db)
{
    // Repairs a local dev database where __EFMigrationsHistory exists but tables are missing.
    db.Database.ExecuteSqlRaw("""
IF OBJECT_ID(N'[dbo].[Gyms]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Gyms] (
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Latitude] [decimal](10,8) NOT NULL,
        [Longitude] [decimal](11,8) NOT NULL,
        [RadiusMeters] [int] NOT NULL CONSTRAINT [DF_Gyms_RadiusMeters] DEFAULT (50),
        CONSTRAINT [PK_Gyms] PRIMARY KEY ([Id])
    );
END;

IF OBJECT_ID(N'[dbo].[Members]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Members] (
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Phone] [nvarchar](20) NOT NULL,
        [FcmToken] [nvarchar](max) NULL,
        [CreatedAt] [datetime2] NOT NULL CONSTRAINT [DF_Members_CreatedAt] DEFAULT (GETUTCDATE()),
        CONSTRAINT [PK_Members] PRIMARY KEY ([Id])
    );
END;

IF OBJECT_ID(N'[dbo].[Attendances]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Attendances] (
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [MemberId] [int] NOT NULL,
        [GymId] [int] NOT NULL,
        [CheckedIn] [datetime2] NOT NULL,
        [CheckedOut] [datetime2] NULL,
        [Source] [nvarchar](10) NOT NULL CONSTRAINT [DF_Attendances_Source] DEFAULT (N'auto'),
        CONSTRAINT [PK_Attendances] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Attendances_Members] FOREIGN KEY ([MemberId]) REFERENCES [dbo].[Members] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Attendances_Gyms] FOREIGN KEY ([GymId]) REFERENCES [dbo].[Gyms] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Members_Phone' AND [object_id] = OBJECT_ID(N'[dbo].[Members]'))
    CREATE UNIQUE INDEX [IX_Members_Phone] ON [dbo].[Members] ([Phone]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Attendances_MemberId_CheckedOut' AND [object_id] = OBJECT_ID(N'[dbo].[Attendances]'))
    CREATE INDEX [IX_Attendances_MemberId_CheckedOut] ON [dbo].[Attendances] ([MemberId], [CheckedOut]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Attendances_MemberId_CheckedIn' AND [object_id] = OBJECT_ID(N'[dbo].[Attendances]'))
    CREATE INDEX [IX_Attendances_MemberId_CheckedIn] ON [dbo].[Attendances] ([MemberId], [CheckedIn]);

IF NOT EXISTS (SELECT 1 FROM [dbo].[Gyms] WHERE [Id] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[Gyms] ON;
    INSERT INTO [dbo].[Gyms] ([Id], [Name], [Latitude], [Longitude], [RadiusMeters])
    VALUES (1, N'Fitness Factor HQ', 3.1390, 101.6869, 50);
    SET IDENTITY_INSERT [dbo].[Gyms] OFF;
END;
""");
}
