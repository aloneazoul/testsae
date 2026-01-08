using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyApi.Data;

[ApiController]
[Route("health")]
public class HealthController : ControllerBase
{
    private readonly AppDbContext _db;

    public HealthController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet("db")]
    public async Task<IActionResult> CheckDb()
    {
        await _db.Database.OpenConnectionAsync();
        await _db.Database.CloseConnectionAsync();
        return Ok("Connexion PostgreSQL OK");
    }
}
