using MBaumann.QuestManager.Core.Entities;

namespace MBaumann.QuestManager.Core.Exceptions;

public class ObjectifInexistantException : QuestManagerException
{
    public IEnumerable<Objectif> Objectifs { get; private set; } = new Objectif[0];

    public ObjectifInexistantException(IEnumerable<Objectif> objectifs)
        : this()
    {
        Objectifs = objectifs;
    }

    public ObjectifInexistantException(Objectif objectif)
        : base("L'objectif n'existe pas")
    {
        Objectifs = new[] { objectif };
    }
    public ObjectifInexistantException()
        : base("Un ou plusieurs objectifs n'existent pas"){}
}