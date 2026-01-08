using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyApi.Data;

[ApiController]
[Route("init")]
public class InitController : ControllerBase
{
    private readonly AppDbContext _db;

    public InitController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet("db")]
    public async Task<IActionResult> InitDb()
    {
        try
        {
            var createTableSql = @"
            CREATE TABLE IF NOT EXISTS logs (
                id VARCHAR(64) PRIMARY KEY,
                migration_start_time TIMESTAMP NOT NULL,
                sub_job_id VARCHAR(255),
                title TEXT,
                type VARCHAR(100),
                source_id VARCHAR(255),
                source TEXT,
                destination_id VARCHAR(255),
                destination TEXT,
                size BIGINT,
                status VARCHAR(100),
                migration_action VARCHAR(100),
                comment TEXT,
                error_code VARCHAR(50)
            );";

            await _db.Database.ExecuteSqlRawAsync(createTableSql);

            return Ok("Table 'logs' créée si inexistante !");
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Erreur : {ex.Message}");
        }
    }
}
