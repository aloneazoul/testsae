namespace MBaumann.QuestManager.ConsoleApp.Menu.Interfaces;

public interface IMenuStrategy
{
    public void Afficher();
    public string Description { get; }
    public string MenuOption { get; }
}