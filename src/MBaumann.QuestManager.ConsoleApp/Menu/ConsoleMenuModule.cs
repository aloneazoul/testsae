using Autofac;
using MBaumann.QuestManager.ConsoleApp.Menu.Interfaces;
using MBaumann.QuestManager.ConsoleApp.Menu.Strategies;
using MBaumann.QuestManager.ConsoleApp.Menu.Strategies.Joueurs;

namespace MBaumann.QuestManager.ConsoleApp.Menu;

public class ConsoleMenuModule : Module
{
    protected override void Load(ContainerBuilder builder)
    {
        base.Load(builder);
        
        builder.RegisterType<ConsoleMenu>().AsSelf().SingleInstance();
        
        builder
            .RegisterType<CreerJoueurMenuStrategy>()
            .As<IMenuStrategy>()
            .Keyed<IMenuStrategy>(CreerJoueurMenuStrategy.MENU_OPTION)
            .InstancePerDependency();
        
        builder
            .RegisterType<ListerJoueursMenuStrategy>()
            .As<IMenuStrategy>()
            .Keyed<IMenuStrategy>(ListerJoueursMenuStrategy.MENU_OPTION)
            .InstancePerDependency();
        
        builder
            .RegisterType<QuitterApplicationMenuStrategy>()
            .As<IMenuStrategy>()
            .Keyed<IMenuStrategy>(QuitterApplicationMenuStrategy.MENU_OPTION)
            .InstancePerDependency();
        
        builder
            .RegisterType<CancellationTokenSource>()
            .AsSelf()
            .SingleInstance();

        builder
            .Register<CancellationToken>((ctx) =>
            {
                return ctx.Resolve<CancellationTokenSource>().Token;
            });
    }
}