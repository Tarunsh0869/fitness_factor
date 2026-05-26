using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace fitness_factor_api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Gyms",
                columns: table => new
                {
                    Id           = table.Column<int>(nullable: false).Annotation("SqlServer:Identity", "1, 1"),
                    Name         = table.Column<string>(maxLength: 100, nullable: false),
                    Latitude     = table.Column<decimal>(type: "decimal(10,8)", nullable: false),
                    Longitude    = table.Column<decimal>(type: "decimal(11,8)", nullable: false),
                    RadiusMeters = table.Column<int>(nullable: false, defaultValue: 50)
                },
                constraints: table => table.PrimaryKey("PK_Gyms", x => x.Id));

            migrationBuilder.CreateTable(
                name: "Members",
                columns: table => new
                {
                    Id        = table.Column<int>(nullable: false).Annotation("SqlServer:Identity", "1, 1"),
                    Name      = table.Column<string>(maxLength: 100, nullable: false),
                    Phone     = table.Column<string>(maxLength: 20, nullable: false),
                    FcmToken  = table.Column<string>(nullable: true),
                    CreatedAt = table.Column<DateTime>(nullable: false, defaultValueSql: "GETUTCDATE()")
                },
                constraints: table => table.PrimaryKey("PK_Members", x => x.Id));

            migrationBuilder.CreateTable(
                name: "Attendances",
                columns: table => new
                {
                    Id         = table.Column<int>(nullable: false).Annotation("SqlServer:Identity", "1, 1"),
                    MemberId   = table.Column<int>(nullable: false),
                    GymId      = table.Column<int>(nullable: false),
                    CheckedIn  = table.Column<DateTime>(nullable: false),
                    CheckedOut = table.Column<DateTime>(nullable: true),
                    Source     = table.Column<string>(maxLength: 10, nullable: false, defaultValue: "auto")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Attendances", x => x.Id);
                    table.ForeignKey("FK_Attendances_Members", x => x.MemberId, "Members", "Id", onDelete: ReferentialAction.Cascade);
                    table.ForeignKey("FK_Attendances_Gyms",    x => x.GymId,    "Gyms",    "Id", onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex("IX_Members_Phone",                    "Members",     "Phone",                    unique: true);
            migrationBuilder.CreateIndex("IX_Attendances_MemberId_CheckedOut",  "Attendances", new[] { "MemberId", "CheckedOut" });
            migrationBuilder.CreateIndex("IX_Attendances_MemberId_CheckedIn",   "Attendances", new[] { "MemberId", "CheckedIn" });

            // Seed default gym
            migrationBuilder.InsertData(
                table: "Gyms",
                columns: new[] { "Id", "Name", "Latitude", "Longitude", "RadiusMeters" },
                values: new object[] { 1, "Fitness Factor", 3.1390m, 101.6869m, 50 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable("Attendances");
            migrationBuilder.DropTable("Members");
            migrationBuilder.DropTable("Gyms");
        }
    }
}
