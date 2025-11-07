# DGX Music Database Schema

**Version**: 1.0.0
**Database**: SQLite 3.40+
**ORM**: SQLAlchemy 2.0+

---

## Overview

The DGX Music MVP uses SQLite as its primary database for tracking music generation jobs, prompts, and metadata. The schema is designed to support the full lifecycle of generation requests from creation through completion or failure.

### Design Principles

- **Simplicity**: Two core tables (generations, prompts)
- **Status tracking**: Clear job states (pending → processing → completed/failed)
- **Extensibility**: JSON metadata field for future attributes
- **Analytics**: Prompt tracking for usage patterns

---

## Schema Diagram

```
┌────────────────────────────────────────────────────────────┐
│                     GENERATIONS                            │
├────────────────────────────────────────────────────────────┤
│ id                   TEXT (UUID) PRIMARY KEY              │
│ prompt               TEXT NOT NULL                        │
│ model_name           TEXT NOT NULL                        │
│ model_version        TEXT                                 │
│ duration_seconds     REAL NOT NULL                        │
│ sample_rate          INTEGER NOT NULL                     │
│ channels             INTEGER NOT NULL                     │
│ file_path            TEXT NOT NULL                        │
│ file_size_bytes      INTEGER                              │
│ status               TEXT NOT NULL                        │
│ created_at           TIMESTAMP NOT NULL                   │
│ completed_at         TIMESTAMP                            │
│ generation_time_seconds  REAL                             │
│ error_message        TEXT                                 │
│ metadata             JSON (TEXT)                          │
└────────────────────────────────────────────────────────────┘
         │
         │ (tracked via track_prompt_usage)
         ▼
┌────────────────────────────────────────────────────────────┐
│                       PROMPTS                              │
├────────────────────────────────────────────────────────────┤
│ id                   INTEGER PRIMARY KEY AUTOINCREMENT    │
│ text                 TEXT NOT NULL UNIQUE                 │
│ used_count           INTEGER DEFAULT 1                    │
│ first_used_at        TIMESTAMP NOT NULL                   │
│ last_used_at         TIMESTAMP NOT NULL                   │
└────────────────────────────────────────────────────────────┘
```

---

## Table Specifications

### `generations`

Tracks music generation jobs from creation through completion.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID v4 identifier |
| `prompt` | TEXT | NOT NULL | User's text prompt describing desired music |
| `model_name` | TEXT | NOT NULL | AI model name (e.g., "musicgen-small") |
| `model_version` | TEXT | | Model version/checkpoint identifier |
| `duration_seconds` | REAL | NOT NULL | Target audio duration in seconds |
| `sample_rate` | INTEGER | NOT NULL | Audio sample rate (Hz, typically 32000) |
| `channels` | INTEGER | NOT NULL | Audio channels (1=mono, 2=stereo) |
| `file_path` | TEXT | NOT NULL | Relative path to generated WAV file |
| `file_size_bytes` | INTEGER | | File size in bytes (NULL until completed) |
| `status` | TEXT | NOT NULL | Job status (see Status Values below) |
| `created_at` | TIMESTAMP | NOT NULL | Job creation timestamp (UTC) |
| `completed_at` | TIMESTAMP | | Job completion timestamp (UTC) |
| `generation_time_seconds` | REAL | | Time taken to generate audio |
| `error_message` | TEXT | | Error details if status=failed |
| `metadata` | TEXT | | JSON metadata (BPM, key, tempo, etc.) |

#### Status Values

- `pending`: Job created, waiting to be processed
- `processing`: Job is currently being generated
- `completed`: Job finished successfully
- `failed`: Job failed with error

#### Indexes

- `idx_generations_status` on `status` - Fast filtering by status
- `idx_generations_created_at` on `created_at DESC` - Recent generations first
- `idx_generations_model_name` on `model_name` - Filter by model
- `idx_generations_completed_at` on `completed_at DESC` - Recent completions

#### Example Records

```sql
-- Pending generation
INSERT INTO generations VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'trap beat with heavy 808 bass at 140 BPM',
    'musicgen-small',
    NULL,
    16.0,
    32000,
    2,
    'outputs/a1b2c3d4.wav',
    NULL,
    'pending',
    '2025-11-07 10:00:00',
    NULL,
    NULL,
    NULL,
    NULL
);

-- Completed generation
INSERT INTO generations VALUES (
    'b2c3d4e5-f6a7-8901-bcde-f12345678901',
    'chill lo-fi hip hop with piano',
    'musicgen-small',
    '1.0',
    30.0,
    32000,
    2,
    'outputs/b2c3d4e5.wav',
    5242880,
    'completed',
    '2025-11-07 09:00:00',
    '2025-11-07 09:00:22',
    22.3,
    NULL,
    '{"bpm": 90, "key": "Am", "genre": "lo-fi"}'
);
```

---

### `prompts`

Tracks unique prompts and their usage statistics for analytics.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Auto-incrementing ID |
| `text` | TEXT | NOT NULL UNIQUE | Unique prompt text |
| `used_count` | INTEGER | DEFAULT 1 | Number of times this prompt was used |
| `first_used_at` | TIMESTAMP | NOT NULL | First use timestamp (UTC) |
| `last_used_at` | TIMESTAMP | NOT NULL | Most recent use timestamp (UTC) |

#### Indexes

- `idx_prompts_text` on `text` - Fast lookup by prompt text

#### Example Records

```sql
INSERT INTO prompts VALUES (
    1,
    'trap beat with heavy 808 bass at 140 BPM',
    3,
    '2025-11-07 09:00:00',
    '2025-11-07 11:30:00'
);

INSERT INTO prompts VALUES (
    2,
    'chill lo-fi hip hop with piano',
    1,
    '2025-11-07 10:15:00',
    '2025-11-07 10:15:00'
);
```

---

## Metadata JSON Schema

The `generations.metadata` field stores JSON with optional attributes:

```json
{
  "bpm": 140,              // Beats per minute (integer or float)
  "key": "Cm",             // Musical key
  "tempo": "fast",         // Tempo descriptor
  "genre": "trap",         // Music genre
  "instruments": ["808", "hi-hat", "snare"],  // Instruments detected/used
  "energy": 0.85,          // Energy level (0-1)
  "danceability": 0.75     // Danceability score (0-1)
}
```

All fields are optional and can be extended as needed.

---

## Relationships

Currently there are no formal foreign key relationships. The `prompts` table is populated automatically via `track_prompt_usage()` when generations are created.

Future versions may add:
- Foreign key from `generations.prompt` to `prompts.id`
- Separate `models` table for model metadata
- `users` table for multi-user support

---

## Database Operations

### Initialization

```python
from services.storage import init_db

# Initialize database (creates tables if they don't exist)
init_db()
```

Or via CLI:
```bash
just db-init
```

### CRUD Examples

```python
from services.storage import (
    get_session,
    create_generation,
    get_generation,
    complete_generation,
    get_database_stats
)

# Create a generation
with get_session() as session:
    gen = create_generation(
        session=session,
        prompt="hip hop beat",
        model_name="musicgen-small",
        duration_seconds=16.0,
        sample_rate=32000,
        channels=2,
        file_path="outputs/test.wav",
        metadata={"bpm": 120}
    )
    gen_id = gen.id

# Retrieve a generation
with get_session() as session:
    gen = get_generation(session, gen_id)
    print(f"Status: {gen.status}")

# Mark as completed
with get_session() as session:
    complete_generation(
        session,
        gen_id,
        generation_time=18.5,
        file_size_bytes=5000000
    )

# Get statistics
with get_session() as session:
    stats = get_database_stats(session)
    print(f"Total generations: {stats['total_generations']}")
```

---

## Migrations

Database schema changes are managed with Alembic.

### Create a Migration

```bash
# Auto-generate migration from model changes
alembic revision --autogenerate -m "Add new field"
```

### Apply Migrations

```bash
# Upgrade to latest
alembic upgrade head

# Or via just
just db-migrate
```

### Rollback

```bash
# Downgrade one version
alembic downgrade -1

# Downgrade to specific version
alembic downgrade <revision>
```

### Current Migration

- **Version**: 001
- **Description**: Initial schema
- **File**: `alembic/versions/001_initial_schema.py`

---

## Performance Considerations

### Query Optimization

1. **Use indexes**: All common query patterns are indexed
2. **Limit results**: Use `limit` parameter in query functions
3. **Filter by status**: Use status filter for pending/completed queries
4. **Pagination**: Use `offset` and `limit` for large result sets

### Example Optimized Queries

```python
# Get recent completed generations (uses idx_generations_completed_at)
completed = get_all_generations(
    session,
    status=GenerationStatus.COMPLETED,
    limit=20
)

# Get pending jobs (uses idx_generations_status)
pending = get_pending_generations(session, limit=100)

# Check most used prompts (natural index on used_count)
popular = get_most_used_prompts(session, limit=10)
```

---

## Data Retention

### Current Policy (MVP)

- No automatic cleanup
- Manual deletion via `delete_generation()`
- Database can be reset with `just db-reset` (WARNING: deletes all data)

### Future Enhancements (Phase 2)

- Automatic cleanup of old generations (>30 days)
- Archive completed generations to PostgreSQL
- Periodic vacuum of SQLite database

---

## Backup & Recovery

### Backup

```bash
# Backup database file
cp data/generations.db data/generations_backup_$(date +%Y%m%d).db

# Or export to SQL
sqlite3 data/generations.db .dump > backup.sql
```

### Recovery

```bash
# Restore from file backup
cp data/generations_backup_20251107.db data/generations.db

# Or restore from SQL dump
sqlite3 data/generations.db < backup.sql
```

---

## Database File Location

**Default**: `data/generations.db`

Can be overridden via environment variable:
```bash
export DATABASE_URL="sqlite:///path/to/custom.db"
```

---

## Troubleshooting

### Database locked

SQLite uses file-level locking. If you get "database locked" errors:

1. Ensure only one process is writing
2. Use WAL mode (future enhancement)
3. Check for hung connections

### Schema out of sync

If tables don't match models:

```bash
# Reset database (WARNING: deletes all data)
just db-reset

# Or run migrations
just db-migrate
```

### Corrupted database

```bash
# Check integrity
sqlite3 data/generations.db "PRAGMA integrity_check;"

# If corrupted, restore from backup
cp data/generations_backup.db data/generations.db
```

---

## Testing

### Unit Tests

```bash
# Test models (no database required)
pytest tests/unit/test_models.py -v
```

### Integration Tests

```bash
# Test database operations (uses temp database)
pytest tests/integration/test_database.py -v
```

### Coverage

```bash
# Run with coverage
just test-coverage
```

Target: 90%+ coverage on storage module

---

## Future Enhancements (Phase 2+)

### Planned Schema Changes

1. **Foreign key relationships**
   - Link generations to prompts via foreign key
   - Cascade delete support

2. **New tables**
   - `users`: Multi-user support
   - `models`: Model metadata and versions
   - `audio_analysis`: Extracted audio features

3. **PostgreSQL migration**
   - Connection pooling
   - Better concurrent access
   - Full-text search on prompts

4. **Additional indexes**
   - Full-text index on prompt text
   - Compound indexes for complex queries

---

## References

- **Schema Definition**: `services/storage/schema.py`
- **ORM Models**: `services/storage/models.py`
- **Database Operations**: `services/storage/database.py`
- **Migrations**: `alembic/versions/`
- **Tests**: `tests/unit/test_models.py`, `tests/integration/test_database.py`

---

**Last Updated**: November 7, 2025
**Schema Version**: 1.0.0
**Migration**: 001
