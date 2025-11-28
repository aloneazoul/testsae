using MBaumann.QuestManager.Core.Interfaces.Entities;

namespace MBaumann.QuestManager.Core.Interfaces.Repositories;

/// <summary>
///     Base entity repository
/// </summary>
/// <typeparam name="TEntity">Entity type</typeparam>
public interface IEntityRepository<TEntity> where TEntity : IBaseEntity
{
    /// <summary>
    ///     Ajoute une entité dans la repository
    /// </summary>
    /// <param name="obj">Entité à ajouter</param>
    void Ajouter(TEntity obj);

    /// <summary>
    ///     Récupère une entité dans le repository
    /// </summary>
    /// <param name="id">UUID de l'entité</param>
    /// <returns>L'entité</returns>
    TEntity Recuperer(Guid id);

    /// <summary>
    ///     Liste les entités
    /// </summary>
    /// <returns>Entités</returns>
    IQueryable<TEntity> Lister();
}