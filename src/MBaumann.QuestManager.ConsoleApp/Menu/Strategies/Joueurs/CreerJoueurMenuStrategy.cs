using MBaumann.QuestManager.Core.Interfaces.Services;

namespace MBaumann.QuestManager.ConsoleApp.Menu.Strategies.Joueurs;

public class CreerJoueurMenuStrategy : ABaseJoueurMenuStrategy
{
    public CreerJoueurMenuStrategy(IJoueurService service) : base(service)
    {
    }

    public const string MENU_OPTION = "1";
    public override string Description { get; } = "Créer un joueur";
    public override string MenuOption { get; } = MENU_OPTION;

    protected override void Action()
    {
        Console.WriteLine("Création d'un joueur");
        string nom;

        do
        {
            Console.Write("Saisir un nom de joueur : ");
            nom = Console.ReadLine();
        } while (String.IsNullOrWhiteSpace(nom));

        Service.Creer(nom);
    }
}