# Storage Service

Database operations and ORM models for DGX Music.

## Overview

The storage service provides SQLite-based persistence for:
- Music generation jobs and their lifecycle
- Prompt tracking and usage analytics
- Metadata storage (BPM, key, genre, etc.)

### Key Features

- **SQLAlchemy ORM**: Type-safe database operations
- **Alembic migrations**: Schema version control
- **Transaction support**: Automatic commit/rollback
- **Prompt analytics**: Track popular prompts
- **Status tracking**: Full job lifecycle management

## Quick Start

### Initialize Database

```python
from services.storage import init_db

init_db()
```

Or via CLI:
```bash
just db-init
```

### Create a Generation

```python
from services.storage import get_session, create_generation

with get_session() as session:
    gen = create_generation(
        session=session,
        prompt="hip hop beat at 140 BPM",
        model_name="musicgen-small",
        duration_seconds=16.0,
        sample_rate=32000,
        channels=2,
        file_path="outputs/gen_123.wav",
        metadata={"bpm": 140, "genre": "hip hop"}
    )
    print(f"Created: {gen.id}")
```

### Query Generations

```python
from services.storage import get_session, get_all_generations, GenerationStatus

with get_session() as session:
    # Get all pending jobs
    pending = get_all_generations(
        session,
        status=GenerationStatus.PENDING,
        limit=10
    )

    for gen in pending:
        print(f"{gen.id}: {gen.prompt}")
```

### Update Status

```python
from services.storage import get_session, complete_generation

with get_session() as session:
    complete_generation(
        session,
        generation_id="abc-123",
        generation_time=18.5,
        file_size_bytes=5000000,
        metadata={"bpm": 140}
    )
```

## Module Structure

```
services/storage/
├── __init__.py          # Public API exports
├── schema.py            # SQL schema and status constants
├── models.py            # SQLAlchemy ORM models
├── database.py          # Database connection and CRUD operations
└── README.md           # This file
```

## API Reference

### Database Management

#### `init_db(database_url: Optional[str] = None)`

Initialize the database and create tables.

**Parameters:**
- `database_url`: Optional database URL (default: `sqlite:///data/generations.db`)

**Example:**
```python
init_db()  # Use default
init_db("sqlite:///custom.db")  # Custom path
```

#### `get_session() -> Generator[Session, None, None]`

Context manager for database sessions with automatic commit/rollback.

**Example:**
```python
with get_session() as session:
    # Your database operations
    gen = create_generation(session, ...)
    # Auto-commit on success, rollback on error
```

#### `reset_database()`

Drop and recreate all tables. **WARNING: Deletes all data!**

#### `get_database_stats(session: Session) -> Dict[str, Any]`

Get database statistics (counts by status, total prompts).

### Generation CRUD

#### `create_generation(...) -> Generation`

Create a new generation record.

**Required Parameters:**
- `session`: Database session
- `prompt`: User's text prompt
- `model_name`: AI model name
- `duration_seconds`: Target duration
- `sample_rate`: Audio sample rate
- `channels`: Number of channels (1 or 2)
- `file_path`: Path to output file

**Optional Parameters:**
- `model_version`: Model version string
- `metadata`: Dictionary of metadata

**Returns:** Created `Generation` object

#### `get_generation(session: Session, generation_id: str) -> Optional[Generation]`

Retrieve a generation by ID.

#### `get_all_generations(session, limit=100, offset=0, status=None) -> List[Generation]`

Get all generations with optional filtering.

#### `update_generation_status(session, generation_id, status, error_message=None)`

Update generation status.

#### `complete_generation(session, generation_id, generation_time, file_size_bytes, metadata=None)`

Mark generation as completed with metadata.

#### `delete_generation(session, generation_id) -> bool`

Delete a generation record.

#### `get_pending_generations(session, limit=100) -> List[Generation]`

Get all pending generations.

#### `count_generations(session, status=None) -> int`

Count generations with optional status filter.

### Prompt Tracking

#### `track_prompt_usage(session, prompt_text) -> Prompt`

Track prompt usage (creates new or increments existing).

#### `get_prompt_by_text(session, text) -> Optional[Prompt]`

Get a prompt by its text.

#### `get_most_used_prompts(session, limit=10) -> List[Prompt]`

Get most frequently used prompts.

## Models

### Generation

Represents a music generation job.

**Properties:**
- `id`: UUID string (auto-generated)
- `prompt`: User's text prompt
- `model_name`: AI model used
- `status`: Job status (pending/processing/completed/failed)
- `created_at`: Creation timestamp
- `completed_at`: Completion timestamp
- `metadata`: JSON metadata dict

**Methods:**
- `is_pending`, `is_processing`, `is_complete`, `is_failed`: Status checks
- `is_finished`: True if complete or failed
- `get_metadata()`: Parse metadata JSON
- `set_metadata(dict)`: Set metadata from dict
- `mark_processing()`: Update status to processing
- `mark_completed(time)`: Mark as completed
- `mark_failed(error)`: Mark as failed
- `to_dict()`: Convert to dictionary

### Prompt

Tracks unique prompts and usage.

**Properties:**
- `id`: Auto-incrementing integer
- `text`: Unique prompt text
- `used_count`: Number of uses
- `first_used_at`: First use timestamp
- `last_used_at`: Last use timestamp

**Methods:**
- `increment_usage()`: Increment usage count
- `to_dict()`: Convert to dictionary

## Status Constants

From `GenerationStatus`:
- `PENDING`: "pending"
- `PROCESSING`: "processing"
- `COMPLETED`: "completed"
- `FAILED`: "failed"

## Database Schema

See [docs/database-schema.md](../../docs/database-schema.md) for full schema documentation.

### Tables

**generations**
- Tracks music generation jobs
- Primary key: UUID
- Indexes on: status, created_at, model_name, completed_at

**prompts**
- Tracks unique prompts
- Primary key: Auto-increment integer
- Unique constraint on text

## Migrations

Database migrations are managed with Alembic.

### Run Migrations

```bash
just db-migrate
```

Or directly:
```bash
alembic upgrade head
```

### Create a Migration

```bash
alembic revision --autogenerate -m "Description"
```

### Rollback

```bash
alembic downgrade -1
```

## Testing

### Unit Tests

Test models without database:
```bash
pytest tests/unit/test_models.py -v
```

### Integration Tests

Test database operations with temp database:
```bash
pytest tests/integration/test_database.py -v
```

### Coverage

```bash
pytest tests/ --cov=services.storage --cov-report=html
```

Target: 90%+ coverage

## Examples

### Complete Workflow

```python
from services.storage import (
    init_db,
    get_session,
    create_generation,
    get_generation,
    complete_generation,
    GenerationStatus
)

# Initialize database
init_db()

# Create generation
with get_session() as session:
    gen = create_generation(
        session=session,
        prompt="trap beat 140 BPM",
        model_name="musicgen-small",
        duration_seconds=16.0,
        sample_rate=32000,
        channels=2,
        file_path="outputs/test.wav"
    )
    gen_id = gen.id

# Mark as processing
with get_session() as session:
    gen = get_generation(session, gen_id)
    gen.mark_processing()

# ... generate audio ...

# Mark as completed
with get_session() as session:
    complete_generation(
        session,
        gen_id,
        generation_time=18.5,
        file_size_bytes=5242880,
        metadata={"bpm": 140, "key": "Cm"}
    )

# Retrieve and check
with get_session() as session:
    gen = get_generation(session, gen_id)
    print(f"Status: {gen.status}")
    print(f"Time: {gen.generation_time_seconds}s")
    print(f"Metadata: {gen.get_metadata()}")
```

### Batch Operations

```python
from services.storage import get_session, get_pending_generations

# Process pending jobs
with get_session() as session:
    pending = get_pending_generations(session, limit=10)

    for gen in pending:
        print(f"Processing: {gen.prompt}")
        gen.mark_processing()
        # Process job...
```

### Analytics

```python
from services.storage import (
    get_session,
    get_database_stats,
    get_most_used_prompts
)

with get_session() as session:
    # Overall stats
    stats = get_database_stats(session)
    print(f"Total: {stats['total_generations']}")
    print(f"Completed: {stats['completed_generations']}")

    # Popular prompts
    popular = get_most_used_prompts(session, limit=5)
    for prompt in popular:
        print(f"{prompt.text}: {prompt.used_count} uses")
```

## Error Handling

The context manager automatically handles errors:

```python
try:
    with get_session() as session:
        gen = create_generation(session, ...)
        # If error occurs, transaction is rolled back
        raise Exception("Something went wrong")
except Exception as e:
    print(f"Error: {e}")
    # Session is closed, transaction rolled back
```

## Configuration

### Database URL

Set via environment variable:
```bash
export DATABASE_URL="sqlite:///path/to/db.db"
```

Default: `sqlite:///data/generations.db`

### Connection Options

For SQLite, the following options are set:
- `check_same_thread=False`: Allow multi-threaded access
- `echo=False`: Disable SQL logging (set to True for debugging)

## Performance Tips

1. **Use indexes**: Query by status, created_at, etc. (indexed fields)
2. **Limit results**: Always use `limit` parameter for large datasets
3. **Batch operations**: Process multiple records in one session
4. **Close sessions**: Use context manager to ensure cleanup

## Troubleshooting

### Database locked

SQLite uses file-level locking. If locked:
- Ensure only one process writes
- Check for hung connections
- Consider WAL mode (future)

### Migration errors

If migration fails:
```bash
# Check current version
alembic current

# Rollback and retry
alembic downgrade -1
alembic upgrade head
```

### Schema mismatch

If tables don't match models:
```bash
just db-reset  # WARNING: Deletes data
just db-migrate
```

## Future Enhancements

Phase 2+ improvements:
- PostgreSQL migration
- Connection pooling
- Read replicas
- Full-text search on prompts
- Foreign key relationships
- Cascade deletes
- WAL mode for better concurrency

## References

- **Schema Documentation**: [docs/database-schema.md](../../docs/database-schema.md)
- **Models**: `models.py`
- **Database Operations**: `database.py`
- **Tests**: `tests/unit/test_models.py`, `tests/integration/test_database.py`

---

**Version**: 1.0.0
**Last Updated**: November 7, 2025
