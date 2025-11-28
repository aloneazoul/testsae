using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;

namespace MBaumann.QuestManager.Core.Interfaces.Services;

/// <summary>
///     Service de gestino des récompenses
/// </summary>
public interface IRecompenseService
{
    /// <summary>
    ///     Créée une nouvelle récompense
    /// </summary>
    /// <param name="nom">Nom de la récompense</param>
    /// <param name="quantite">Quantité de la récompense</param>
    /// <returns>Nouvelle récompense</returns>
    Recompense Creer(string nom, int quantite);

    /// <summary>
    ///     Récupère une récompense
    /// </summary>
    /// <param name="id">UUID de la récompense</param>
    /// <returns>Récompense</returns>
    Recompense Recuperer(Guid id);

    /// <summary>
    ///     Liste les récompenses
    /// </summary>
    /// <param name="offset">Nombres d'éléments à ignorer</param>
    /// <param name="limit">Nombre d'éléments à récupérer</param>
    /// <param name="predicate">Filtres</param>
    /// <returns>List de récompenses</returns>
    IEnumerable<Recompense> Lister(int offset = 0, int limit = 20,
        Expression<Func<Recompense, bool>>? predicate = null);
}