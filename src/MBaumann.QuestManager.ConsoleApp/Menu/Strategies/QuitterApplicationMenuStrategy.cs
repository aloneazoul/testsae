namespace MBaumann.QuestManager.ConsoleApp.Menu.Strategies;

public class QuitterApplicationMenuStrategy : BaseMenuStrategy
{
    private readonly CancellationTokenSource _source;

    public QuitterApplicationMenuStrategy(CancellationTokenSource source)
    {
        _source =  source;
    }
    public override string Description { get; } = "Quitter l'application";
    public const string MENU_OPTION = "x";
    public override string MenuOption { get; } = MENU_OPTION;
    protected override void Action()
    {
        _source.Cancel();
    }
}