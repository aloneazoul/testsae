using System.Diagnostics;
using Autofac;
using MBaumann.QuestManager.ConsoleApp.Menu;
using MBaumann.QuestManager.Core;
using MBaumann.QuestManager.Core.Interfaces.Services;
using MBaumann.QuestManager.Core.Services;
using MBaumann.QuestManager.InMemoryStorage;
using MBaumann.QuestManager.InMemoryStorage.Repositories;

namespace MBaumann.QuestManager.ConsoleApp;

internal class Program
{
    private static void Main(string[] args)
    {
        var containerBuilder = new ContainerBuilder();

        containerBuilder.RegisterModule<CoreModule>();
        containerBuilder.RegisterModule<InMemoryStorageModule>();
        containerBuilder.RegisterModule<ConsoleMenuModule>();

        using var container = containerBuilder.Build();
        using var scope = container.BeginLifetimeScope();
        
        var menu = scope.Resolve<ConsoleMenu>();

        menu.Afficher();
    }
}