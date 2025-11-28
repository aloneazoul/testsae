using MBaumann.QuestManager.Core.Interfaces.Entities;

namespace MBaumann.QuestManager.Core.Entities;

public class Objectif : IBaseEntity
{
    public enum TypeObjectif
    {
        Collecte,
        Abattre,
        Rencontrer
    }

    public string Intitule { get; set; }
    public int Quantite { get; set; }
    public TypeObjectif Type { get; set; }
    public Guid Id { get; set; }
}