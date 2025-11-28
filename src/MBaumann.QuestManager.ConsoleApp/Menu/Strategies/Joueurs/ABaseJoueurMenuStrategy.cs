using MBaumann.QuestManager.Core.Interfaces.Services;

namespace MBaumann.QuestManager.ConsoleApp.Menu.Strategies.Joueurs;

public abstract class ABaseJoueurMenuStrategy : BaseMenuStrategy
{
    protected ABaseJoueurMenuStrategy(IJoueurService service)
    {
        this.Service = service;
    }

    protected IJoueurService Service { get; init; }
}