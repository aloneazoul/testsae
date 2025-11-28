using Autofac;
using MBaumann.QuestManager.Core.Interfaces.Repositories;
using MBaumann.QuestManager.InMemoryStorage.Repositories;

namespace MBaumann.QuestManager.InMemoryStorage;

public class InMemoryStorageModule : Module
{
    protected override void Load(ContainerBuilder builder)
    {
        base.Load(builder);
        
        builder
            .RegisterType<JoueurRepository>()
            .As<IJoueurRepository>()
            .SingleInstance();
        
        builder
            .RegisterType<ObjectifRepository>()
            .As<IObjectifRepository>()
            .SingleInstance();
        
        builder
            .RegisterType<QueteRepository>()
            .As<IQueteRepository>()
            .SingleInstance();
        
        builder
            .RegisterType<RecompenseRepository>()
            .As<IRecompenseRepository>()
            .SingleInstance();
    }
}