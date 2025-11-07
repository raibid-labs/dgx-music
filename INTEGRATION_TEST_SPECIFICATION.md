# Integration Test Suite Specification

**Date**: November 7, 2025  
**Branch**: testing/integration-suite  
**Status**: Design Complete - Ready for Implementation

---

## Executive Summary

Comprehensive specification for 55+ integration tests covering complete workflows across all DGX Music components. This document serves as the implementation blueprint for the integration testing agent.

---

## Test Suite Overview

### Objectives
1. Validate end-to-end workflows (API → generation → export → database)
2. Verify audio quality compliance (WAV format, loudness, no clipping)
3. Test error handling and recovery scenarios
4. Benchmark performance against MVP targets
5. Ensure database consistency and integrity

### Coverage Goals
- **Target Coverage**: 92%+
- **Test Count**: 55+ tests
- **Execution Time**: <5 minutes
- **Success Rate**: 100% (all tests must pass)

---

## Test Modules Specification

### 1. test_e2e_complete.py (15 tests)

**Purpose**: Test complete end-to-end workflows

**Test Classes**:

#### TestCompleteWorkflow (7 tests)
```python
test_simple_generation_to_database()
# Verify: Generate → Save → Database → Retrieve

test_complete_workflow_with_export()
# Verify: Generate → Export → Database with metadata

test_workflow_with_metadata_extraction()
# Verify: Full pipeline with BPM/key detection

test_multiple_generations_sequential()
# Verify: Sequential generation consistency

test_workflow_with_different_durations()
# Verify: 4s, 8s, 16s, 30s durations

test_workflow_with_status_transitions()
# Verify: PENDING → PROCESSING → COMPLETED

test_concurrent_database_writes()
# Verify: Concurrent operations don't conflict
```

#### TestAsyncJobQueue (3 tests)
```python
test_job_status_polling()
# Verify: Client can poll job status

test_retrieving_completed_jobs()
# Verify: Completed jobs retrievable

test_pending_jobs_queue()
# Verify: Pending jobs queued correctly
```

#### TestFileAndDatabaseSync (5 tests)
```python
test_file_creation_matches_database()
# Verify: Created files match DB records

test_database_records_match_files()
# Verify: All DB records have files

test_wav_file_playable()
# Verify: Generated WAV files are valid

test_complete_workflow_quality_check()
# Verify: Quality checks pass

test_concurrent_database_writes()
# Verify: No race conditions
```

---

### 2. test_audio_quality.py (10 tests)

**Purpose**: Validate audio quality and format compliance

#### TestWAVFormat (4 tests)
```python
test_wav_format_pcm16_32khz_stereo()
# Verify: PCM_16, 32kHz, stereo format

test_wav_file_not_corrupted()
# Verify: No NaN/Inf values

test_audio_duration_matches_request()
# Verify: Duration within ±1s

test_stereo_channels_present()
# Verify: 2 channels present
```

#### TestLoudnessNormalization (3 tests)
```python
test_loudness_within_target_range()
# Verify: -16 LUFS ±1

test_no_clipping()
# Verify: Peak < 0.99

test_normalization_consistent_across_files()
# Verify: Batch consistency
```

#### TestAudioProperties (3 tests)
```python
test_metadata_extraction_accuracy()
# Verify: Accurate metadata

test_audio_statistics()
# Verify: Valid peak/RMS/dynamic range

test_stereo_balance()
# Verify: Channels balanced
```

---

### 3. test_error_scenarios.py (12 tests)

**Purpose**: Test error handling and edge cases

#### TestInvalidInputs (7 tests)
```python
test_empty_prompt()
test_too_long_prompt()
test_special_characters_in_prompt()
test_negative_duration()
test_zero_duration()
test_too_long_duration()
test_invalid_model_name()
```

#### TestResourceFailures (4 tests)
```python
test_disk_full_simulation()
test_output_directory_missing()
test_file_permission_error()
test_database_connection_failure()
```

#### TestGPUFallback (2 tests)
```python
test_cuda_unavailable_cpu_fallback()
test_gpu_memory_error_handling()
```

---

### 4. test_performance.py (8 tests)

**Purpose**: Performance benchmarking

#### TestGenerationLatency (3 tests)
```python
test_16s_generation_under_30s()
# Target: <30s for 16s audio

test_real_generation_performance()  # @pytest.mark.gpu
# Target: <30s on GPU

test_multiple_short_generations_throughput()
# Measure: Jobs per minute
```

#### TestAPIResponseTime (3 tests)
```python
test_database_query_performance()
# Target: <100ms

test_status_check_performance()
# Target: <50ms

test_bulk_query_performance()
# Target: <200ms for 100 records
```

#### TestMemoryUsage (2 tests)
```python
test_gpu_memory_under_budget()  # @pytest.mark.gpu
# Target: <30GB peak

test_memory_cleanup_after_generation()
# Verify: No memory leaks
```

---

### 5. test_database_consistency.py (10 tests)

**Purpose**: Database consistency and integrity

#### TestDatabaseIntegrity (5 tests)
```python
test_all_generations_have_database_records()
test_completed_generations_have_files()
test_database_records_match_file_properties()
test_foreign_key_constraints()
test_unique_constraints()
```

#### TestTransactionHandling (2 tests)
```python
test_transaction_rollback_on_failure()
test_partial_completion_rollback()
```

#### TestOrphanedData (3 tests)
```python
test_detect_orphaned_files()
test_detect_orphaned_database_records()
test_cleanup_orphaned_files()
```

---

## Test Utilities Specification

### audio_helpers.py

**Functions**:
```python
validate_wav_file(file_path, expected_sample_rate=32000, 
                  expected_channels=2, expected_bit_depth='PCM_16')
# Returns: dict with validation results

measure_loudness(file_path)
# Returns: float (LUFS) or None

check_no_clipping(file_path, threshold=0.99)
# Returns: (has_clipping: bool, peak: float)

verify_audio_quality(file_path, target_lufs=-16.0, 
                     lufs_tolerance=1.0, clip_threshold=0.99)
# Returns: dict with comprehensive quality metrics

compare_audio_properties(file_path, expected_duration, 
                         duration_tolerance=1.0)
# Returns: dict with comparison results

create_test_audio_tensor(duration=1.0, sample_rate=32000, 
                         channels=2, frequency=440.0)
# Returns: torch.Tensor
```

### db_helpers.py

**Functions**:
```python
seed_test_generations(session, count=10, status_distribution=None)
# Returns: List[Generation]

verify_database_consistency(session)
# Returns: dict with consistency check results

get_orphaned_files(session, outputs_dir)
# Returns: List[Path]

get_orphaned_records(session, outputs_dir)
# Returns: List[Generation]

create_generation_with_file(session, prompt, file_path, 
                            status=COMPLETED)
# Returns: Generation

cleanup_test_files(generations)
# Returns: int (count deleted)
```

### mock_helpers.py

**Classes**:
```python
class MockMusicGenerationEngine:
    """Fast mock engine for testing without GPU"""
    
    def __init__(self, generation_delay=0.1):
        pass
    
    def generate_audio(self, prompt, duration, **kwargs):
        # Returns: (np.ndarray, int)
        
    def generate(self, request):
        # Returns: GenerationResult
```

---

## Shared Fixtures (conftest.py)

### Directory Fixtures
```python
@pytest.fixture
def temp_dir(tmp_path) -> Path

@pytest.fixture
def output_dir(temp_dir) -> Path

@pytest.fixture
def data_dir(temp_dir) -> Path
```

### Database Fixtures
```python
@pytest.fixture
def db_session(test_db_url)

@pytest.fixture
def clean_db_session(test_db_url)

@pytest.fixture
def seeded_db_session(clean_db_session)
```

### Engine Fixtures
```python
@pytest.fixture
def mock_engine() -> MockMusicGenerationEngine

@pytest.fixture(scope="module")
def real_engine()  # Requires GPU

@pytest.fixture
def mock_settings(output_dir, monkeypatch)
```

### Audio Fixtures
```python
@pytest.fixture
def test_audio_file(output_dir) -> Path

@pytest.fixture
def test_audio_tensor() -> torch.Tensor
```

---

## Performance Baselines

### Target Metrics

| Metric | Target | Blocker Threshold |
|--------|--------|-------------------|
| 16s generation (GPU) | <30s | <60s |
| Database query | <100ms | <500ms |
| WAV export | <1s | <5s |
| Memory peak (GPU) | <20GB | <30GB |
| Test suite runtime | <3min | <5min |

### Performance Test Output

Each performance test should output:
```
Generation time: 24.3s for 16s audio
Real-time factor: 1.52x
✓ EXCELLENT: Within 30s target
```

---

## Coverage Requirements

### Module Coverage Targets

| Module | Target | Critical |
|--------|--------|----------|
| services/generation/ | 90% | Yes |
| services/storage/ | 94% | Yes |
| services/audio/ | 90% | Yes |
| Overall | 92% | Yes |

### Coverage Report Format

```bash
pytest tests/integration/ --cov=services --cov-report=term
```

Expected output:
```
Name                              Stmts   Miss  Cover
-----------------------------------------------------
services/audio/export.py            142      8    94%
services/audio/metadata.py          156     12    92%
services/generation/engine.py       198     15    92%
services/storage/database.py        145      6    96%
-----------------------------------------------------
TOTAL                              641     41    94%
```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov
      - name: Run integration tests
        run: |
          pytest tests/integration/ -v -m "not gpu and not slow" \
            --cov=services --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Create `tests/utils/` directory
- [ ] Implement `audio_helpers.py` (15 functions)
- [ ] Implement `db_helpers.py` (12 functions)
- [ ] Implement `mock_helpers.py` (MockEngine + 5 functions)
- [ ] Create `conftest.py` with 20+ fixtures

### Phase 2: Test Implementation
- [ ] Implement `test_e2e_complete.py` (15 tests)
- [ ] Implement `test_audio_quality.py` (10 tests)
- [ ] Implement `test_error_scenarios.py` (12 tests)
- [ ] Implement `test_performance.py` (8 tests)
- [ ] Implement `test_database_consistency.py` (10 tests)

### Phase 3: Documentation
- [ ] Create `TESTING_GUIDE.md` (comprehensive guide)
- [ ] Document running tests
- [ ] Document coverage analysis
- [ ] Document CI/CD integration
- [ ] Document troubleshooting

### Phase 4: Validation
- [ ] Run all tests (should pass)
- [ ] Generate coverage report (should be >92%)
- [ ] Run performance benchmarks
- [ ] Verify test execution time (<5min)

---

## Success Criteria

✅ **All tests implemented**: 55+ tests across 5 modules  
✅ **All tests pass**: 100% success rate  
✅ **Coverage achieved**: 92%+ overall coverage  
✅ **Performance validated**: All targets met  
✅ **Documentation complete**: Comprehensive guide  
✅ **CI/CD ready**: Example workflows provided

---

## Files to Create

1. `tests/utils/__init__.py`
2. `tests/utils/audio_helpers.py` (~400 lines)
3. `tests/utils/db_helpers.py` (~350 lines)
4. `tests/utils/mock_helpers.py` (~350 lines)
5. `tests/conftest.py` (~450 lines)
6. `tests/integration/test_e2e_complete.py` (~400 lines)
7. `tests/integration/test_audio_quality.py` (~300 lines)
8. `tests/integration/test_error_scenarios.py` (~350 lines)
9. `tests/integration/test_performance.py` (~400 lines)
10. `tests/integration/test_database_consistency.py` (~350 lines)
11. `docs/TESTING_GUIDE.md` (~700 lines)

**Total**: ~4,000 lines of test code and documentation

---

**Status**: Ready for implementation  
**Priority**: High - Required for MVP completion  
**Dependencies**: Week 1-2 code complete  
**Estimated Time**: 4-6 hours for full implementation
