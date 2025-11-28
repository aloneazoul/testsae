using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Guards;
using MBaumann.QuestManager.Core.Interfaces.Repositories;
using MBaumann.QuestManager.Core.Interfaces.Services;

namespace MBaumann.QuestManager.Core.Services;

/// <inheritdoc cref="IQueteService" />
public class QueteService : IQueteService
{
    private readonly IObjectifService _objectifService;
    private readonly IQueteRepository _queteRepository;
    private readonly IRecompenseService _recompenseService;

    /// <summary>
    ///     Ctor
    /// </summary>
    /// <param name="queteRepository">Repository pour les quêtes</param>
    /// <param name="recompenseService">Service pour les récompenses</param>
    /// <param name="objectifService">Service pour les objectifs</param>
    public QueteService(
        IQueteRepository queteRepository,
        IRecompenseService recompenseService,
        IObjectifService objectifService
    )
    {
        _queteRepository = queteRepository;
        _recompenseService = recompenseService;
        _objectifService = objectifService;
    }

    public Quete Creer(string titre, IEnumerable<Objectif> objectifs, IEnumerable<Recompense> recompenses)
    {
        objectifs.ObjectifsExistent(_objectifService.Lister());
        
        var quete = new Quete
        {
            Id = Guid.NewGuid(),
            Titre = titre,
            Objectifs = objectifs,
            Recompenses = recompenses
        };

        _queteRepository.Ajouter(quete);

        return quete;
    }

    public Quete Recuperer(Guid id)
    {
        return _queteRepository.Recuperer(id);
    }

    public IEnumerable<Quete> Lister(int offset = 0, int limit = 20, Expression<Func<Quete, bool>>? predicate = null)
    {
        var liste = _queteRepository.Lister();

        if (predicate != null) liste = liste.Where(predicate);

        return liste.Skip(offset).Take(limit);
    }
}