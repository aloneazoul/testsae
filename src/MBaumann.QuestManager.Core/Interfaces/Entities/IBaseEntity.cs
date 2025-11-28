namespace MBaumann.QuestManager.Core.Interfaces.Entities;

/// <summary>
///     Base entity for repository constraints
/// </summary>
public interface IBaseEntity
{
    /// <summary>
    ///     Entity UUID
    /// </summary>
    public Guid Id { get; set; }
}