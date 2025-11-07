# DGX Music - MVP Scope & Implementation Plan

**Version**: 1.0
**Target Timeline**: 6 weeks
**Status**: Planning Complete
**Risk Level**: Medium (ARM64 compatibility unverified)

---

## Executive Summary

Based on comprehensive technical analysis, the MVP will deliver a **simplified single-service Python application** that generates music from text prompts using MusicGen Small, with manual Ardour integration via file export. This approach validates core technology on DGX Spark while deferring production complexity.

### Key Simplifications from Full Architecture

| Component | Full Production | MVP |
|-----------|-----------------|-----|
| AI Models | 4 models (YuE, DiffRhythm, MusicGen, JASCO) | 1 model (MusicGen Small) |
| Memory Usage | 110GB optimized | 15-25GB |
| Database | PostgreSQL + Redis + FAISS | SQLite only |
| Deployment | Kubernetes microservices | Single Python process (systemd) |
| DAW Integration | Real-time MCP | Manual WAV file import |
| Timeline | 12+ weeks | 6 weeks |

---

## MVP Scope Statement

### What We're Building

A command-line and API-based music generation tool that:

1. **Accepts text prompts** describing desired music (genre, tempo, instruments, mood)
2. **Generates 16-30 second music clips** using MusicGen Small model
3. **Exports professional-quality WAV files** ready for Ardour import
4. **Stores generation history** in SQLite database
5. **Runs reliably on DGX Spark** with <30GB memory footprint

### Success Criteria

- ✅ Generate 10 diverse music clips from text prompts
- ✅ <30 second generation latency per clip
- ✅ Audio quality acceptable for production demos
- ✅ System stable for 24+ continuous hours
- ✅ Complete documentation (API + user guide)
- ✅ Validated on DGX Spark ARM64 architecture

### Explicitly OUT OF SCOPE

The following features are deferred to post-MVP phases:

**Phase 2 (Weeks 7-12):**
- PostgreSQL migration with connection pooling
- FAISS vector search for prompt similarity
- Multi-model orchestration (DiffRhythm, JASCO)
- Real-time Ardour MCP integration
- Redis-based job queue

**Phase 3 (Weeks 13+):**
- Full song generation with YuE
- Source separation with Demucs
- Kubernetes deployment with horizontal scaling
- Production monitoring (Prometheus/Grafana)
- Genre-specific fine-tuning pipeline

---

## Critical Technical Validations

### Must Validate BEFORE Implementation

**Priority 1: DGX Spark CUDA Compatibility**

```bash
# Test GPU availability
python -c "import torch; print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"

# Expected output:
# CUDA Available: True
# GPU: NVIDIA GB10 Grace Blackwell

# If False: MVP requires CPU fallback or cloud hybrid strategy
```

**Priority 2: MusicGen ARM64 Compatibility**

```python
from audiocraft.models import MusicGen
model = MusicGen.get_pretrained('small')
model.set_generation_params(duration=8)
wav = model.generate(['test prompt'])

# If this fails: Critical blocker, requires alternative model
```

**Priority 3: Generation Performance Benchmark**

```python
import time
start = time.time()
wav = model.generate(['trap beat 140 BPM with 808 bass'])
elapsed = time.time() - start

# Target: <30 seconds for 16s audio
# If >60 seconds: Consider cloud GPU or smaller model
```

---

## MVP Architecture

### System Overview

```
┌──────────────────────────────────────────────────────┐
│                 CLI / API Interface                   │
│            (Typer CLI + FastAPI REST)                │
└────────────────────┬─────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────┐
│           Generation Service (Python)                 │
│  ┌─────────────────────────────────────────────┐    │
│  │  MusicGen Small (8GB VRAM)                  │    │
│  │  - Text prompt encoding                      │    │
│  │  - Audio generation (16-30s clips)          │    │
│  │  - WAV export + normalization               │    │
│  └─────────────────────────────────────────────┘    │
│                                                       │
│  ┌─────────────────────────────────────────────┐    │
│  │  Generation Queue (Python asyncio)          │    │
│  │  - In-memory job queue                      │    │
│  │  - Sequential processing                    │    │
│  └─────────────────────────────────────────────┘    │
└────────────────────┬─────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────┐
│              Storage Layer                            │
│  ┌──────────────────┐  ┌──────────────────────┐     │
│  │  SQLite DB       │  │  Local Filesystem    │     │
│  │  - Generations   │  │  - WAV files         │     │
│  │  - Prompts       │  │  - Metadata          │     │
│  └──────────────────┘  └──────────────────────┘     │
└──────────────────────────────────────────────────────┘
```

### Technology Stack

**Core Framework:**
- **Language**: Python 3.10+
- **AI Model**: MusicGen Small (300M params, 8GB VRAM)
- **ML Framework**: PyTorch 2.3+ with CUDA 12.1

**API Layer:**
- **REST API**: FastAPI 0.100+
- **CLI**: Typer 0.9+
- **Validation**: Pydantic 2.0+

**Audio Processing:**
- **Export**: soundfile + scipy
- **Analysis**: librosa (optional)
- **Normalization**: pyloudnorm

**Storage:**
- **Database**: SQLite 3.40+
- **ORM**: SQLAlchemy 2.0+
- **Migrations**: Alembic

**Deployment:**
- **Process Management**: systemd
- **Web Server**: Uvicorn (ASGI)
- **Reverse Proxy**: Nginx (optional)

**Development Tools:**
- **Task Runner**: Just
- **Scripting**: Nushell
- **Testing**: pytest
- **Linting**: ruff

---

## Database Schema (SQLite)

```sql
-- generations table
CREATE TABLE generations (
    id TEXT PRIMARY KEY,              -- UUID
    prompt TEXT NOT NULL,
    model_name TEXT NOT NULL,         -- "musicgen-small"
    model_version TEXT,
    duration_seconds REAL NOT NULL,
    sample_rate INTEGER NOT NULL,
    channels INTEGER NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes INTEGER,
    status TEXT NOT NULL,             -- pending/processing/completed/failed
    created_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    generation_time_seconds REAL,
    error_message TEXT,
    metadata JSON                     -- BPM, key, etc.
);

-- prompts table (for analytics)
CREATE TABLE prompts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    text TEXT NOT NULL,
    used_count INTEGER DEFAULT 1,
    first_used_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP NOT NULL
);

-- indices for performance
CREATE INDEX idx_generations_status ON generations(status);
CREATE INDEX idx_generations_created_at ON generations(created_at DESC);
CREATE INDEX idx_prompts_text ON prompts(text);
```

---

## API Specification

### REST Endpoints

**POST /api/v1/generate**

Request:
```json
{
  "prompt": "trap beat with heavy 808 bass and sharp hi-hats at 140 BPM",
  "duration": 16,
  "temperature": 1.0,
  "top_k": 250,
  "top_p": 0.0
}
```

Response:
```json
{
  "job_id": "gen_a1b2c3d4",
  "status": "pending",
  "estimated_time_seconds": 20,
  "created_at": "2025-11-06T10:30:00Z"
}
```

**GET /api/v1/jobs/{job_id}**

Response:
```json
{
  "job_id": "gen_a1b2c3d4",
  "status": "completed",
  "prompt": "trap beat with heavy 808 bass...",
  "file_url": "/api/v1/files/gen_a1b2c3d4.wav",
  "metadata": {
    "duration": 16.0,
    "sample_rate": 32000,
    "channels": 2,
    "file_size_mb": 3.1
  },
  "generation_time_seconds": 18.4,
  "created_at": "2025-11-06T10:30:00Z",
  "completed_at": "2025-11-06T10:30:18Z"
}
```

**GET /api/v1/files/{filename}**

Returns: WAV file download

**GET /api/v1/history**

Response:
```json
{
  "generations": [
    {
      "job_id": "gen_a1b2c3d4",
      "prompt": "trap beat...",
      "status": "completed",
      "created_at": "2025-11-06T10:30:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "page_size": 20
}
```

### CLI Commands

```bash
# Generate music
dgx-music generate "hip hop beat 90 BPM with jazz piano sample"

# With options
dgx-music generate "dubstep drop 140 BPM" --duration 30 --output custom.wav

# Check status
dgx-music status gen_a1b2c3d4

# List history
dgx-music history --limit 10

# Export Ardour template
dgx-music export-ardour gen_a1b2c3d4 --output project.ardour
```

---

## File System Structure

```
/opt/dgx-music/                      # Installation root
├── models/                          # AI model weights
│   └── musicgen-small/
│       ├── compression_model.pt     (2.8GB)
│       ├── lm_model.pt              (5.1GB)
│       └── config.json
│
├── data/                            # SQLite database
│   └── generations.db
│
├── outputs/                         # Generated audio
│   ├── gen_a1b2c3d4.wav
│   └── gen_e5f6g7h8.wav
│
├── logs/                            # Application logs
│   ├── app.log
│   └── generation.log
│
└── config/                          # Configuration
    └── settings.yaml

/tmp/dgx-music/                      # Temporary files
└── processing/                      # Generation scratch space
```

---

## Memory Budget (Revised)

| Component | Memory | Notes |
|-----------|--------|-------|
| **OS + System** | 10GB | Linux kernel, services |
| **MusicGen Small** | 8GB | Model weights in GPU VRAM |
| **PyTorch Runtime** | 4GB | CUDA context, buffers |
| **FastAPI Server** | 2GB | Web server, routing |
| **SQLite** | 0.5GB | Database cache |
| **Audio Buffers** | 2GB | Generation working memory |
| **Application Logic** | 1.5GB | Python runtime |
| **Safety Margin** | 5GB | Spikes, fragmentation |
| **TOTAL** | **33GB** | **Well within 128GB** |

**Peak Memory Test:**
- Start API server: ~12GB
- Load MusicGen model: +8GB = 20GB
- Generate audio: +6GB = 26GB
- Export WAV: +2GB = 28GB
- **Maximum observed: 30GB** ✅

---

## Performance Targets

### Generation Latency

| Duration | Target Latency | Acceptable Max |
|----------|----------------|----------------|
| 8 seconds | 10s | 20s |
| 16 seconds | 18s | 30s |
| 30 seconds | 28s | 45s |

### System Performance

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Cold start time | <15s | Model load → first generation |
| Warm generation | <20s | Subsequent generations |
| Memory footprint | <30GB | Peak resident set size |
| Uptime | 24h+ | Stability test |
| Error rate | <5% | Failed generations / total |

---

## 6-Week Implementation Timeline

### Week 1: Foundation & Validation

**WS1: Core Engine (Start)**
- Day 1-2: DGX Spark environment setup
  - Python 3.10 virtual environment
  - CUDA/PyTorch installation
  - GPU compatibility validation ⚠️ CRITICAL
- Day 3-4: MusicGen installation
  - Download model weights (8GB)
  - Test generation on DGX Spark
  - Benchmark performance
- Day 5: Project structure
  - Repository setup
  - Python package scaffolding
  - Database schema design

**WS2: Storage (Start)**
- Day 1-3: SQLite schema implementation
- Day 4-5: ORM models (SQLAlchemy)

### Week 2: Core Development

**WS1: Core Engine**
- Day 1-2: Generation service implementation
  - Prompt encoding
  - Model inference
  - Error handling
- Day 3-4: Audio export pipeline
  - WAV generation
  - Loudness normalization
  - Metadata extraction
- Day 5: Job queue implementation
  - In-memory async queue
  - Status tracking

**WS2: Storage**
- Day 1-2: Database operations
  - CRUD operations
  - Query optimization
- Day 3-5: File management
  - Storage structure
  - Cleanup utilities

### Week 3: API Layer

**WS1: Core Engine (Complete)**
- Day 1-2: Integration testing
- Day 3-5: Performance optimization

**WS3: Interface (Start)**
- Day 1-3: FastAPI implementation
  - REST endpoints
  - Request validation
  - Response formatting
- Day 4-5: CLI tool (Typer)
  - Generate command
  - Status command
  - History command

### Week 4: Polish & Features

**WS2: Audio Export (Complete)**
- Day 1-2: Ardour template generator
- Day 3-5: Batch export utilities

**WS3: Interface**
- Day 1-3: Error handling
  - Validation errors
  - Generation failures
  - Retry logic
- Day 4-5: Documentation
  - API docs (OpenAPI)
  - CLI help text

### Week 5: Testing & Integration

**WS4: Testing (Start)**
- Day 1-2: Unit tests
  - Model loading
  - Generation pipeline
  - Database operations
- Day 3-4: Integration tests
  - End-to-end workflows
  - Error scenarios
- Day 5: Performance benchmarking
  - Latency tests
  - Memory profiling
  - Load testing

**WS5: Deployment (Start)**
- Day 1-3: Systemd service
  - Unit file creation
  - Auto-restart configuration
- Day 4-5: Deployment scripts
  - Installation script
  - Configuration management

### Week 6: Deployment & Documentation

**WS4: Testing (Complete)**
- Day 1-2: User acceptance testing
  - 10 test scenarios
  - Bug fixes
- Day 3-5: Documentation
  - Installation guide
  - User manual
  - API reference
  - Troubleshooting guide

**WS5: Deployment (Complete)**
- Day 1-2: Production deployment
  - DGX Spark installation
  - Service activation
  - Health monitoring
- Day 3: Final testing
  - 24-hour stability run
  - Performance validation
- Day 4-5: Handoff
  - Knowledge transfer
  - Operational runbook
  - Support documentation

---

## Risk Mitigation Strategies

### Critical Risk: CUDA Incompatibility

**Scenario**: PyTorch CUDA not available on DGX Spark ARM64

**Mitigation Options:**
1. **CPU Fallback**: Use PyTorch CPU-only mode
   - Impact: 5-10x slower generation
   - Acceptable for MVP validation
2. **Cloud Hybrid**: Local orchestration, remote GPU generation
   - Use AWS/GCP GPU instances
   - DGX Spark handles storage/API only
3. **Alternative Model**: Switch to Stable Audio Open Small
   - Explicitly ARM-optimized
   - Lower quality but proven ARM64 compatibility

**Decision Tree:**
```
CUDA Available?
├─ YES → Continue with MusicGen Small ✅
└─ NO  → Run CPU benchmark
         ├─ <60s per generation → Acceptable, use CPU
         └─ >60s per generation → Cloud hybrid or alternative model
```

### High Risk: Poor Audio Quality

**Scenario**: MusicGen Small output insufficient for demos

**Mitigation:**
1. Upgrade to MusicGen Medium (16GB VRAM)
   - Still within DGX Spark budget
   - 2x slower generation acceptable
2. Increase generation parameters
   - Higher temperature for diversity
   - Longer context for coherence
3. Post-processing pipeline
   - Add mastering effects
   - Compression + EQ

### Medium Risk: Timeline Slip

**Scenario**: Development falls behind schedule

**Mitigation:**
1. **Week 3 Checkpoint**: If >3 days behind, drop WS3 (Interface)
   - Use CLI only for MVP
   - Manual testing instead of automated
2. **Week 5 Checkpoint**: If >5 days behind, reduce testing scope
   - Core functionality only
   - Defer documentation to Phase 2

### Low Risk: DGX Spark Access Issues

**Scenario**: Hardware not available for development

**Mitigation:**
1. Develop on standard x86_64 Linux
2. Deploy to cloud ARM64 instance for testing (AWS Graviton)
3. Final deployment on DGX Spark when available

---

## Definition of Done

### MVP is complete when:

**Functional Requirements:**
- ✅ CLI tool can generate music from text prompts
- ✅ API endpoints return valid responses
- ✅ Generated audio files play correctly in Ardour
- ✅ SQLite database stores generation history
- ✅ System runs stable for 24+ hours

**Quality Requirements:**
- ✅ 90%+ test coverage on core generation logic
- ✅ API documentation complete (Swagger UI)
- ✅ User guide written with examples
- ✅ Deployment runbook validated on DGX Spark

**Performance Requirements:**
- ✅ <30s generation latency for 16s audio
- ✅ <30GB peak memory usage
- ✅ <5% generation failure rate

**Operational Requirements:**
- ✅ Systemd service auto-restarts on failure
- ✅ Logs aggregated via journald
- ✅ Health check endpoint responds
- ✅ Backup/restore procedures documented

---

## Post-MVP Roadmap

### Phase 2: Production Features (Weeks 7-12)

**Database Migration:**
- PostgreSQL with connection pooling
- Migration scripts from SQLite
- Performance optimization

**Advanced Search:**
- FAISS vector embeddings
- Semantic prompt search
- Recommendation engine

**Multi-Model Support:**
- DiffRhythm integration (rhythm control)
- JASCO chord conditioning
- Model selection API

**Real-Time Integration:**
- Ardour MCP server
- Live audio streaming
- MIDI import/export

### Phase 3: Scale & Quality (Weeks 13-20)

**Full Song Generation:**
- YuE integration (cloud hybrid)
- Long-form composition
- Vocal synthesis (optional)

**Production Deployment:**
- Kubernetes migration
- Horizontal scaling
- Load balancing

**Advanced Features:**
- Source separation (Demucs)
- Audio-to-MIDI transcription
- Style transfer

**Quality Improvements:**
- Genre-specific fine-tuning
- Custom model training pipeline
- A/B testing framework

---

## Success Metrics

### MVP Launch Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Successful generations | 100 | First month |
| Average latency | <25s | Per generation |
| User satisfaction | 4/5 | Survey |
| System uptime | 99%+ | First week |
| Documentation completeness | 100% | Coverage checklist |

### Key Performance Indicators

- **Technical Debt**: <10% of code requires refactoring
- **Bug Count**: <5 critical bugs in first week
- **API Stability**: <1% error rate
- **User Adoption**: 3+ active users within first week
- **Generation Quality**: 80%+ prompts produce usable audio

---

## Conclusion

This MVP represents a **pragmatic, achievable** path to validating AI music generation on DGX Spark. By focusing on a single proven model (MusicGen Small) and deferring complex infrastructure, we can deliver a working system in 6 weeks while de-risking the full production architecture.

**Key Success Factors:**
1. ✅ Early CUDA/ARM64 validation (Week 1 Day 1)
2. ✅ Simplified tech stack (SQLite, single model)
3. ✅ Clear scope boundaries (no feature creep)
4. ✅ Risk mitigation strategies (CPU fallback, cloud hybrid)
5. ✅ Realistic timeline (6 weeks with contingencies)

**Go/No-Go Decision Points:**
- **Week 1 Day 2**: CUDA validation complete → Continue or pivot
- **Week 3 Day 1**: Core generation working → Continue or reassess
- **Week 5 Day 5**: Integration tests pass → Deploy or debug

---

**Document Version**: 1.0
**Last Updated**: November 6, 2025
**Next Review**: Week 3 (milestone checkpoint)
**Owner**: Engineering Team
**Status**: APPROVED FOR IMPLEMENTATION ✅
