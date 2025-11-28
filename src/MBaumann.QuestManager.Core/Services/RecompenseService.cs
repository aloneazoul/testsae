using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;
using MBaumann.QuestManager.Core.Interfaces.Services;

namespace MBaumann.QuestManager.Core.Services;

/// <inheritdoc cref="IRecompenseService" />
public class RecompenseService : IRecompenseService
{
    private readonly IRecompenseRepository _repository;

    /// <summary>
    ///     Ctor
    /// </summary>
    /// <param name="repository">Repository pour les récompenses</param>
    public RecompenseService(IRecompenseRepository repository)
    {
        _repository = repository;
    }

    public Recompense Creer(string nom, int quantite)
    {
        var recompense = new Recompense
        {
            Nom = nom,
            Quantite = quantite,
            Id = Guid.NewGuid()
        };

        _repository.Ajouter(recompense);

        return recompense;
    }

    public Recompense Recuperer(Guid id)
    {
        return _repository.Recuperer(id);
    }

    public IEnumerable<Recompense> Lister(int offset = 0, int limit = 20,
        Expression<Func<Recompense, bool>>? predicate = null)
    {
        var liste = _repository.Lister();

        if (predicate != null) liste = liste.Where(predicate);

        return liste.Skip(offset).Take(limit);
    }
}