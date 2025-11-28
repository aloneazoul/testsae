using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;

namespace MBaumann.QuestManager.InMemoryStorage.Repositories;

/// <summary>
///     Repository de quêtes
/// </summary>
public class QueteRepository : AInMemoryRepository<Quete>, IQueteRepository
{
}