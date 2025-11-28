using MBaumann.QuestManager.Core.Interfaces.Services;

namespace MBaumann.QuestManager.ConsoleApp.Menu.Strategies.Joueurs;

public class ListerJoueursMenuStrategy : ABaseJoueurMenuStrategy
{
    public ListerJoueursMenuStrategy(IJoueurService service) : base(service)
    {
    }

    public const string MENU_OPTION = "2";
    public override string Description { get; } = "Lister les joueurs";
    public override string MenuOption { get; } =  MENU_OPTION;

    protected override void Action()
    {
        Console.WriteLine("Liste des joueurs :");
        foreach (var joueur in Service.Lister())
        {
            Console.WriteLine("- Le joueur {0} a {1} points d'exprience", joueur.Nom, joueur.Experience);
        }
    }
}