using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyApi.Models;

[Table("logs")]
public class Logs
{
    [Key]
    [Column("id")]
    [MaxLength(64)]
    public string Id { get; set; } = null!;

    [Column("migration_start_time")]
    public DateTime MigrationStartTime { get; set; }

    [Column("sub_job_id")]
    [MaxLength(255)]
    public string? SubJobId { get; set; }

    [Column("title")]
    public string? Title { get; set; }

    [Column("type")]
    [MaxLength(100)]
    public string? Type { get; set; }

    [Column("source_id")]
    [MaxLength(255)]
    public string? SourceId { get; set; }

    [Column("source")]
    public string? Source { get; set; }

    [Column("destination_id")]
    [MaxLength(255)]
    public string? DestinationId { get; set; }

    [Column("destination")]
    public string? Destination { get; set; }

    [Column("size")]
    public long? Size { get; set; }

    [Column("status")]
    [MaxLength(100)]
    public string? Status { get; set; }

    [Column("migration_action")]
    [MaxLength(100)]
    public string? MigrationAction { get; set; }

    [Column("comment")]
    public string? Comment { get; set; }

    [Column("error_code")]
    [MaxLength(50)]
    public string? ErrorCode { get; set; }
}
