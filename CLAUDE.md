# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DGX Music is an AI-powered music generation platform targeting NVIDIA DGX Spark hardware (ARM64 architecture, 128GB unified memory, GB10 Grace Blackwell GPU). The system generates music from text prompts using state-of-the-art models (MusicGen, DiffRhythm, YuE) with integration into Ardour DAW for professional music production.

**Current Status**: MVP Phase - Building simplified single-service Python application before full production architecture.

## Critical Context

### Hardware Constraints
- **Platform**: DGX Spark (ARM64, not x86_64)
- **Memory Budget**: MVP targets <30GB (production: 110GB)
- **GPU**: CUDA compatibility UNVERIFIED on DGX Spark ARM64
- **First Priority**: Validate GPU/CUDA before any model work (see `just validate-gpu`)

### MVP Simplifications
The research documents propose a comprehensive production architecture, but MVP intentionally simplifies:
- **Models**: MusicGen Small only (defer YuE, DiffRhythm, JASCO to Phase 2)
- **Database**: SQLite (defer PostgreSQL, Redis, FAISS)
- **Deployment**: Systemd service (defer Kubernetes)
- **Integration**: Manual WAV export to Ardour (defer real-time MCP)

**Read `docs/MVP_SCOPE.md` before implementing features** - it contains critical risk assessments and technical validations.

## Development Workflow

### Task Automation (Justfile)
All development tasks use `just` command runner:

```bash
# First-time setup
just init                    # Create venv, directories, install deps

# Critical validation (MUST RUN FIRST)
just validate-gpu            # Check CUDA availability - BLOCKER if fails
just test-model             # Benchmark generation performance

# Development
just serve                   # Run FastAPI server on :8000
just generate "prompt" 16    # Generate music via CLI
just test                    # Run all tests
just test-coverage          # Tests with coverage report

# Code quality
just lint                    # Ruff linting
just format                 # Code formatting
just typecheck              # MyPy type checking
just quality                # Run all checks

# Database
just db-init                # Initialize SQLite database
just db-migrate             # Run Alembic migrations

# Deployment
just deploy-dgx             # Deploy to DGX Spark via systemd
```

### Development Environment
- Tilt is configured but **not used for MVP** (systemd deployment only)
- For Phase 2 Kubernetes: `tilt up` will work
- Current MVP: `just serve` runs local FastAPI server

## Architecture Patterns

### Orchestrator/Subagent Pattern
This repo uses GitHub Actions + orchestrator agents for parallel development:

1. **GitHub Issues** define work (see issues #1-#5 for MVP workstreams)
2. **Orchestrator** (`scripts/nushell/launch-orchestrator.nu`) monitors issues
3. **Agents** spawned automatically when questions answered
4. **Pattern**: Based on `~/raibid-labs/raibid-ci` - review `ORCHESTRATOR.md` there

**Key Workflow**:
- Issues with `draft` label → Enrichment agent improves issue quality
- Issues with answers → Orchestrator spawns implementation agent
- Agents create PRs → Merge triggers dependent work

### Service Structure (Future)
```
services/
├── orchestrator/      # Main orchestration logic
├── generation/       # AI model inference (MusicGen)
│   ├── api.py       # FastAPI endpoints
│   ├── engine.py    # Core generation logic
│   └── cli.py       # Typer CLI
├── rendering/        # Audio export, normalization
├── storage/          # SQLite ORM, migrations
└── integration/      # Ardour template generation
```

## Key Documentation References

### Must Read First
1. **`docs/MVP_SCOPE.md`** - Defines what to build, what to defer, risk mitigations
2. **`docs/CUTTING_EDGE_MUSIC_AI_2024_2025.md`** - Model survey, ARM64 compatibility notes
3. **GitHub Issues #1-#5** - Workstream definitions with acceptance criteria

### Architecture Documents
- **`docs/DGX_SPARK_PRODUCTION_ARCHITECTURE.md`** - Full production vision (mostly deferred)
- **`docs/AI_MUSIC_GENERATION_RESEARCH.md`** - Pipeline details (text→MIDI→audio)
- **`docs/AI_MUSIC_TRAINING_RESEARCH.md`** - Training strategies (Phase 3+)

## Critical Validations

### Week 1 Day 1 Blockers
Before writing ANY generation code:

```python
# 1. GPU/CUDA validation
import torch
assert torch.cuda.is_available(), "CUDA unavailable - MVP BLOCKED"

# 2. MusicGen ARM64 compatibility
from audiocraft.models import MusicGen
model = MusicGen.get_pretrained('small')
# If this fails: Switch to CPU fallback or cloud hybrid

# 3. Performance benchmark
# Target: <30s for 16s audio
# If >60s: Escalate to alternative model
```

**Contingency Plans** (see MVP_SCOPE.md Section 5):
- CUDA fails → CPU fallback or cloud GPU hybrid
- Poor quality → Upgrade to MusicGen Medium (16GB)
- Timeline slip → Drop web UI (WS3), use CLI only

## Technology Stack

### Core Dependencies
- **AI/ML**: PyTorch 2.3+, AudioCraft, Transformers
- **API**: FastAPI, Uvicorn, Pydantic
- **Audio**: librosa, soundfile, pyloudnorm
- **Database**: SQLAlchemy 2.0, Alembic
- **CLI**: Typer, Rich
- **Testing**: pytest, pytest-cov

### Platform-Specific Notes
- **ARM64**: Use PyTorch ARM64 builds, verify all models compile
- **CUDA**: Requires 12.1+ (verify on DGX Spark)
- **Memory**: Peak usage must stay <30GB for MVP

## Testing Strategy

```bash
# Unit tests (fast, no GPU required)
just test-unit

# Integration tests (requires GPU, slower)
just test-integration

# Performance benchmarks (measure latency, memory)
just benchmark
```

**Test Requirements** (from WS4):
- 90%+ coverage on core generation logic
- 10 test scenarios (see MVP_SCOPE.md Week 5)
- Performance validation: <30s latency, <30GB memory

## Database Schema

SQLite with SQLAlchemy ORM (see `docs/MVP_SCOPE.md` for full schema):

```sql
CREATE TABLE generations (
    id TEXT PRIMARY KEY,           -- UUID
    prompt TEXT NOT NULL,
    model_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    status TEXT NOT NULL,          -- pending/processing/completed/failed
    created_at TIMESTAMP,
    metadata JSON
);
```

## Deployment

### MVP Deployment (Current)
```bash
# Deploy to DGX Spark as systemd service
sudo just deploy-dgx

# Service management
sudo systemctl status dgx-music
sudo journalctl -u dgx-music -f
```

### Phase 2 Deployment (Future)
Kubernetes deployment via Tilt (deferred to Week 7+)

## API Structure

FastAPI endpoints (planned):

```
POST   /api/v1/generate      # Submit generation request
GET    /api/v1/jobs/{id}     # Check job status
GET    /api/v1/files/{id}    # Download WAV file
GET    /api/v1/history       # List generation history
GET    /health               # Health check
```

## Parallel Development Notes

**Active Workstreams** (GitHub Issues #1-#5):
- **WS1**: Core Generation Engine (Weeks 1-4) - CRITICAL PATH
- **WS2**: Audio Export & Storage (Weeks 1-3) - CRITICAL PATH
- **WS3**: Web Interface (Weeks 2-4) - OPTIONAL, can drop
- **WS4**: Testing & Docs (Weeks 5-6) - CRITICAL PATH
- **WS5**: DGX Deployment (Weeks 5-6) - CRITICAL PATH

**Dependencies**:
- WS2 depends on WS1 (Week 2+)
- WS3 depends on WS1 (Week 2+)
- WS4/WS5 depend on all (integration phase)

## Memory Budget Awareness

When implementing features, monitor memory:

```bash
# Check current GPU usage
just gpu-status

# Profile memory during development
just profile-memory
```

**Allocation** (MVP):
- MusicGen Small: 8GB GPU VRAM
- PyTorch runtime: 4GB
- FastAPI server: 2GB
- Audio buffers: 2GB
- **Total peak**: ~20GB (10GB margin)

## Out of Scope for MVP

Do NOT implement these without explicit approval:
- Full song generation (YuE) - Phase 3
- Multi-model orchestration - Phase 2
- Real-time DAW integration - Phase 2
- Source separation (Demucs) - Phase 2
- FAISS vector search - Phase 2
- Kubernetes deployment - Phase 2
- PostgreSQL/Redis - Phase 2

Refer questioners to `docs/MVP_SCOPE.md` Section "Explicitly OUT OF SCOPE".

## Troubleshooting

### CUDA Not Available
1. Check PyTorch installation: `pip list | grep torch`
2. Verify CUDA: `nvidia-smi`
3. Test: `just validate-gpu`
4. If fails: Implement CPU fallback (see MVP_SCOPE.md)

### Generation Too Slow
1. Benchmark: `just test-model`
2. If >30s: Acceptable for MVP
3. If >60s: Switch to cloud GPU or Stable Audio Open Small

### Out of Memory
1. Check: `just gpu-status`
2. Reduce audio buffers in code
3. Ensure model loaded on-demand (not persistent)
4. Consider MusicGen Tiny if Small too large

## Related Projects

- **raibid-ci** (`~/raibid-labs/raibid-ci`): Reference for orchestrator pattern
- **ardour-mcp** (`~/raibid-labs/ardour-mcp`): Future DAW integration (Phase 2)

## Performance Targets

| Metric | MVP Target | Production Target |
|--------|-----------|-------------------|
| Generation latency (16s audio) | <30s | <18s |
| Peak memory | <30GB | <110GB |
| Uptime | 24h+ | 99%+ |
| Error rate | <5% | <1% |

Track progress in GitHub Issues milestones.
