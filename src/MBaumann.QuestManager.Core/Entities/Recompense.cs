using MBaumann.QuestManager.Core.Interfaces.Entities;

namespace MBaumann.QuestManager.Core.Entities;

public class Recompense : IBaseEntity
{
    public string Nom { get; set; }
    public int Quantite { get; set; }
    public Guid Id { get; set; }
}