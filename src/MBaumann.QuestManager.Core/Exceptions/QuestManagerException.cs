namespace MBaumann.QuestManager.Core.Exceptions;

/// <summary>
/// Exception de base pour toutes nos exceptions
/// </summary>
public class QuestManagerException : ApplicationException
{
    public QuestManagerException(string message) : base(message){}
}