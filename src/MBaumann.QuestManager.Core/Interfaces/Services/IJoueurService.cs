using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;

namespace MBaumann.QuestManager.Core.Interfaces.Services;

/// <summary>
///     Service de gestion des joueurs
/// </summary>
public interface IJoueurService
{
    /// <summary>
    ///     Créer un nouveau joueur
    /// </summary>
    /// <param name="nom">Nom du joueur</param>
    /// <returns>Nouveau joueur</returns>
    Joueur Creer(string nom);

    /// <summary>
    ///     Récupère un joueur
    /// </summary>
    /// <param name="id">UUID du joueur</param>
    /// <returns>Le joueur</returns>
    Joueur Recuperer(Guid id);

    /// <summary>
    ///     Liste les joueurs
    /// </summary>
    /// <param name="offset">Nombre d'éléments à ignorer</param>
    /// <param name="limit">Nombre d'éléments à récupérer</param>
    /// <param name="predicate">Filtres</param>
    /// <returns>Joueurs</returns>
    IEnumerable<Joueur> Lister(
        int offset = 0,
        int limit = 20,
        Expression<Func<Joueur, bool>>? predicate = null
    );
}