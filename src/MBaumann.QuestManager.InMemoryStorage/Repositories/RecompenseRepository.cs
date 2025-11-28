using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;

namespace MBaumann.QuestManager.InMemoryStorage.Repositories;

/// <summary>
///     Repository de récompenses
/// </summary>
public class RecompenseRepository : AInMemoryRepository<Recompense>, IRecompenseRepository
{
}