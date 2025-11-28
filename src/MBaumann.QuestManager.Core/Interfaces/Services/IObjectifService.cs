using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;

namespace MBaumann.QuestManager.Core.Interfaces.Services;

/// <summary>
///     Service pour les objectifs
/// </summary>
public interface IObjectifService
{
    /// <summary>
    ///     Créée un nouvel objectif
    /// </summary>
    /// <param name="intitule">Intitulé de l'objectif</param>
    /// <param name="quantite">Quantité de l'objectif</param>
    /// <param name="type">Type d'objectif</param>
    /// <returns>Nouvel objectif</returns>
    Objectif Creer(string intitule, int quantite, Objectif.TypeObjectif type);

    /// <summary>
    ///     Récupère un objectif
    /// </summary>
    /// <param name="id">ID de l'objectif</param>
    /// <returns>Objectif</returns>
    Objectif Recuperer(Guid id);

    /// <summary>
    ///     Liste les objectifs
    /// </summary>
    /// <param name="offset">Nombre d'enregistrements à ignorer</param>
    /// <param name="limit">Nombre d'enregistrements à récupérer</param>
    /// <param name="predicate">Filtres</param>
    /// <returns>Liste d'objectifs</returns>
    IEnumerable<Objectif> Lister(int offset = 0, int limit = 20, Expression<Func<Objectif, bool>>? predicate = null);
}