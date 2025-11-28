using Autofac;
using Autofac.Core.Registration;
using MBaumann.QuestManager.ConsoleApp.Menu.Interfaces;

namespace MBaumann.QuestManager.ConsoleApp.Menu;

public class ConsoleMenu
{
    private readonly ILifetimeScope _container;
    private readonly CancellationToken _token;

    public ConsoleMenu(ILifetimeScope container, CancellationToken token)
    {
        _container = container;
        _token = token;
    }
    
    public void Afficher()
    {
        string saisie;

        do
        {
            Console.Clear();
            Console.WriteLine("Menu :");

            foreach (var strategy in _container.Resolve<IEnumerable<IMenuStrategy>>())
            {
                Console.WriteLine("{0} - {1}", strategy.MenuOption, strategy.Description);
            }
            
            Console.WriteLine();
            Console.Write("Saisir une action : ");
            saisie = Console.ReadLine();

            try
            {
                _container.ResolveKeyed<IMenuStrategy>(saisie).Afficher();
            }
            catch (ComponentNotRegisteredException)
            {
                Console.WriteLine("L'option choisie n'est pas valide");
                Console.ReadKey();
            }
            catch (Exception)
            {
                // Silent catch
            }
        } while (_token.IsCancellationRequested == false);
    }
}