using MBaumann.QuestManager.Core.Interfaces.Entities;

namespace MBaumann.QuestManager.Core.Entities;

public class Joueur : IBaseEntity
{
    public enum NiveauJoueur
    {
        Debutant,
        Intermediaire,
        Legende
    }

    public string Nom { get; set; }
    public NiveauJoueur Niveau { get; set; }
    public int Experience { get; set; }
    public Guid Id { get; set; }
}