using MBaumann.QuestManager.Core.Interfaces.Entities;

namespace MBaumann.QuestManager.Core.Entities;

public class Quete : IBaseEntity
{
    public string Titre { get; set; }
    public IEnumerable<Objectif> Objectifs { get; set; }
    public IEnumerable<Recompense> Recompenses { get; set; }
    public Guid Id { get; set; }
}