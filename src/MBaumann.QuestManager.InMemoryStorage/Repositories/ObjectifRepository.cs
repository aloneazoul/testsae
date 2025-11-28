using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;

namespace MBaumann.QuestManager.InMemoryStorage.Repositories;

/// <summary>
///     Repository d'objectifs
/// </summary>
public class ObjectifRepository : AInMemoryRepository<Objectif>, IObjectifRepository
{
}