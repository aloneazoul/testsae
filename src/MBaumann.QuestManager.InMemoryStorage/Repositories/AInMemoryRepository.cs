using MBaumann.QuestManager.Core.Interfaces.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;

namespace MBaumann.QuestManager.InMemoryStorage.Repositories;

/// <summary>
///     Repository de base pour la gestion InMemory
/// </summary>
/// <typeparam name="TEntity">Type de l'entité</typeparam>
public abstract class AInMemoryRepository<TEntity> : IEntityRepository<TEntity>, IDisposable
    where TEntity : IBaseEntity
{
    private readonly IList<TEntity> _entities;

    protected AInMemoryRepository()
    {
        _entities = new List<TEntity>();
    }

    public void Ajouter(TEntity obj)
    {
        _entities.Add(obj);
    }

    public TEntity Recuperer(Guid id)
    {
        return _entities.First(e => e.Id == id);
    }

    public IQueryable<TEntity> Lister()
    {
        return _entities.AsQueryable();
    }

    public void Dispose()
    {
        _entities.Clear();
    }
}