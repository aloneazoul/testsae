using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;
using MBaumann.QuestManager.Core.Interfaces.Services;

namespace MBaumann.QuestManager.Core.Services;

/// <inheritdoc cref="IObjectifService" />
public class ObjectifService : IObjectifService
{
    private readonly IObjectifRepository _repository;

    /// <summary>
    ///     Ctor
    /// </summary>
    /// <param name="repository">Repository pour les objectifs</param>
    public ObjectifService(IObjectifRepository repository)
    {
        _repository = repository;
    }

    public Objectif Creer(string intitule, int quantite, Objectif.TypeObjectif type)
    {
        var objectif = new Objectif
        {
            Id = Guid.NewGuid(),
            Intitule = intitule,
            Quantite = quantite,
            Type = type
        };

        _repository.Ajouter(objectif);

        return objectif;
    }

    public Objectif Recuperer(Guid id)
    {
        return _repository.Recuperer(id);
    }

    public IEnumerable<Objectif> Lister(int offset = 0, int limit = 20,
        Expression<Func<Objectif, bool>>? predicate = null)
    {
        var liste = _repository.Lister();

        if (predicate != null) liste = liste.Where(predicate);

        return liste.Skip(offset).Take(limit);
    }
}