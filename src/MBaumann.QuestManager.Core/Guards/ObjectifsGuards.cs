using MBaumann.QuestManager.Core.Entities;
using MBaumann.QuestManager.Core.Exceptions;

namespace MBaumann.QuestManager.Core.Guards;

public static class ObjectifsGuards
{
    public static void ObjectifsExistent(
        this IEnumerable<Objectif> objectifs,
        IEnumerable<Objectif> reference)
    {
        if (objectifs.Any(o => reference.Count(obj => obj.Id == o.Id
                ) == 0
            )
           )
            throw new ObjectifInexistantException(objectifs);
    }
}