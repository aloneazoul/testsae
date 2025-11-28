using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;

namespace MBaumann.QuestManager.Core.Interfaces.Services;

/// <summary>
///     Service de gestion des quêtes
/// </summary>
public interface IQueteService
{
    /// <summary>
    ///     Créée une nouvelle quête
    /// </summary>
    /// <param name="titre">Titre de la quête</param>
    /// <param name="objectifs">Objectifs de la quête</param>
    /// <param name="recompenses">Récompenses de la quête</param>
    /// <returns>Nouvelle quête</returns>
    Quete Creer(string titre, IEnumerable<Objectif> objectifs, IEnumerable<Recompense> recompenses);

    /// <summary>
    ///     Récupère une quête
    /// </summary>
    /// <param name="id">UUID de la quête</param>
    /// <returns>La quête</returns>
    Quete Recuperer(Guid id);

    /// <summary>
    ///     Liste les quêtes
    /// </summary>
    /// <param name="offset">Nombre d'éléments à ignorer</param>
    /// <param name="limit">Nombre d'éléments à récupérer</param>
    /// <param name="predicate">Filtres</param>
    /// <returns>Liste de quêtes</returns>
    IEnumerable<Quete> Lister(int offset = 0, int limit = 20, Expression<Func<Quete, bool>>? predicate = null);
}