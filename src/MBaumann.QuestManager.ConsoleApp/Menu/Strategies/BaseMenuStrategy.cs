using MBaumann.QuestManager.ConsoleApp.Menu.Interfaces;

namespace MBaumann.QuestManager.ConsoleApp.Menu.Strategies;

public abstract class BaseMenuStrategy : IMenuStrategy
{
    public void Afficher()
    {
        Console.Clear();
        
        Action();
        
        Console.ReadKey();
    }

    public abstract string Description { get; }
    public abstract string MenuOption { get; }

    protected abstract void Action();
}