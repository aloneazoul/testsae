using Autofac;
using MBaumann.QuestManager.Core.Interfaces.Services;
using MBaumann.QuestManager.Core.Services;

namespace MBaumann.QuestManager.Core;

public class CoreModule : Module
{
    protected override void Load(ContainerBuilder builder)
    {
        base.Load(builder);

        builder
            .RegisterType<JoueurService>()
            .As<IJoueurService>()
            .InstancePerDependency();
        
        builder
            .RegisterType<ObjectifService>()
            .As<IObjectifService>()
            .InstancePerDependency();
        
        builder
            .RegisterType<QueteService>()
            .As<IQueteService>()
            .InstancePerDependency();
        
        builder
            .RegisterType<RecompenseService>()
            .As<IRecompenseService>()
            .InstancePerDependency();
    }
}