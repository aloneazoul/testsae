using System.Linq.Expressions;
using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;
using MBaumann.QuestManager.Core.Interfaces.Services;

namespace MBaumann.QuestManager.Core.Services;

/// <inheritdoc cref="IJoueurService" />
public class JoueurService : IJoueurService
{
    private readonly IJoueurRepository _repository;

    /// <summary>
    ///     Ctor
    /// </summary>
    /// <param name="joueurRepository">Repository pour les joueurs</param>
    public JoueurService(IJoueurRepository joueurRepository)
    {
        _repository = joueurRepository;
    }

    public Joueur Creer(string nom)
    {
        var joueur = new Joueur
        {
            Nom = nom,
            Experience = 0,
            Id = Guid.NewGuid(),
            Niveau = Joueur.NiveauJoueur.Debutant
        };

        _repository.Ajouter(joueur);

        return joueur;
    }

    public Joueur Recuperer(Guid id)
    {
        return _repository.Recuperer(id);
    }

    public IEnumerable<Joueur> Lister(int offset = 0, int limit = 20, Expression<Func<Joueur, bool>>? predicate = null)
    {
        var liste = _repository.Lister();

        if (predicate != null) liste = liste.Where(predicate);

        return liste.Skip(offset).Take(limit);
    }
}