using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// 1. Récupération de la connexion
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// 2. Configuration d'Entity Framework avec Postgres
// (On crée un DbContext "à la volée" pour le test, on fera propre plus tard)
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddControllers();

var app = builder.Build();

// 3. Test simple : une route qui dit bonjour et vérifie la BDD
app.MapGet("/ping", async (AppDbContext db) => {
    try {
        // Tente d'ouvrir la connexion pour voir si ça marche
        await db.Database.CanConnectAsync(); 
        return Results.Ok("Pong! Connexion BDD OK 🚀");
    } catch (Exception ex) {
        return Results.Problem($"Erreur BDD : {ex.Message}");
    }
});

app.MapControllers();
app.Run();

// Définition minimale du DbContext pour que ça compile
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
}