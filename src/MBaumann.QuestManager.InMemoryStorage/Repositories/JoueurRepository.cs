using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Interfaces.Repositories;

namespace MBaumann.QuestManager.InMemoryStorage.Repositories;

/// <summary>
///     Repository de joueurs
/// </summary>
public class JoueurRepository : AInMemoryRepository<Joueur>, IJoueurRepository
{
}