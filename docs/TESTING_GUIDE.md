# DGX Music - Testing Guide

**Last Updated**: November 7, 2025
**Status**: Integration Test Suite Complete (55+ tests)

---

## Overview

This guide covers the comprehensive integration test suite for DGX Music, including execution instructions, coverage analysis, and CI/CD integration.

### Test Suite Statistics

- **Total Tests**: 55+
- **Test Files**: 5 integration test modules
- **Test Utilities**: 3 helper modules
- **Coverage Target**: 92%+
- **Execution Time**: <5 minutes (with mock engine)

---

## Test Suite Structure

```
tests/
├── conftest.py                          # Shared fixtures and configuration
├── utils/                               # Test utilities
│   ├── audio_helpers.py                 # WAV validation, loudness measurement
│   ├── db_helpers.py                    # Database seeding, cleanup
│   └── mock_helpers.py                  # Mock generation engine
├── integration/
│   ├── test_e2e_complete.py            # 15 tests: Complete workflows
│   ├── test_audio_quality.py           # 10 tests: Audio quality validation
│   ├── test_error_scenarios.py         # 12 tests: Error handling
│   ├── test_performance.py             # 8 tests: Performance benchmarks
│   └── test_database_consistency.py    # 10 tests: Database integrity
└── unit/                                # Existing unit tests
    ├── test_audio_export.py
    ├── test_audio_metadata.py
    ├── test_audio_storage.py
    ├── test_generation_engine.py
    └── test_models.py
```

---

## Running Tests

### Prerequisites

Ensure you have the test environment set up:

```bash
# Activate virtual environment
source venv/bin/activate

# Install test dependencies
pip install pytest pytest-cov pytest-asyncio httpx
```

### Running All Integration Tests

```bash
# Run all integration tests
pytest tests/integration/ -v

# Run with coverage
pytest tests/integration/ --cov=services --cov-report=html --cov-report=term

# Run specific test file
pytest tests/integration/test_e2e_complete.py -v
```

### Running Specific Test Categories

```bash
# Run only E2E tests
pytest tests/integration/test_e2e_complete.py -v

# Run audio quality tests
pytest tests/integration/test_audio_quality.py -v

# Run error scenario tests
pytest tests/integration/test_error_scenarios.py -v

# Run performance tests (slow)
pytest tests/integration/test_performance.py -v -m slow

# Run database consistency tests
pytest tests/integration/test_database_consistency.py -v
```

### Running with Markers

```bash
# Run only fast tests (skip slow/GPU tests)
pytest tests/integration/ -v -m "not slow and not gpu"

# Run only GPU tests (requires CUDA)
pytest tests/integration/ -v -m gpu

# Run all integration tests (may be slow)
pytest tests/integration/ -v -m integration
```

### Parallel Execution

```bash
# Install pytest-xdist
pip install pytest-xdist

# Run tests in parallel (4 workers)
pytest tests/integration/ -v -n 4
```

---

## Test Modules

### 1. test_e2e_complete.py (15 tests)

**Purpose**: Test complete end-to-end workflows

**Test Classes**:
- `TestCompleteWorkflow`: Basic generation → database workflows
- `TestAsyncJobQueue`: Job queue and status polling
- `TestFileAndDatabaseSync`: File/database synchronization
- `TestPromptVariations`: Various prompt types

**Key Tests**:
- `test_simple_generation_to_database`: Basic workflow
- `test_complete_workflow_with_export`: Full export pipeline
- `test_workflow_with_metadata_extraction`: Metadata integration
- `test_multiple_generations_sequential`: Sequential generation
- `test_job_status_polling`: Job polling behavior
- `test_concurrent_database_writes`: Concurrent operations

**Run**:
```bash
pytest tests/integration/test_e2e_complete.py -v
```

---

### 2. test_audio_quality.py (10 tests)

**Purpose**: Validate audio quality and format compliance

**Test Classes**:
- `TestWAVFormat`: WAV format validation
- `TestLoudnessNormalization`: Loudness normalization
- `TestAudioProperties`: Audio property validation
- `TestBatchQuality`: Batch generation consistency
- `TestComprehensiveQuality`: Complete quality verification

**Key Tests**:
- `test_wav_format_pcm16_32khz_stereo`: Format compliance
- `test_loudness_within_target_range`: LUFS target (±1)
- `test_no_clipping`: Clipping detection (peak < 0.99)
- `test_audio_duration_matches_request`: Duration accuracy
- `test_metadata_extraction_accuracy`: Metadata validation

**Run**:
```bash
pytest tests/integration/test_audio_quality.py -v
```

---

### 3. test_error_scenarios.py (12 tests)

**Purpose**: Test error handling and edge cases

**Test Classes**:
- `TestInvalidInputs`: Invalid request handling
- `TestResourceFailures`: Resource failure scenarios
- `TestGPUFallback`: CPU fallback when GPU unavailable
- `TestCorruptedData`: Corrupted data handling
- `TestInterruptedOperations`: Interrupted operation recovery
- `TestMissingDependencies`: Missing dependency handling
- `TestEdgeCases`: Edge cases and boundaries

**Key Tests**:
- `test_empty_prompt`: Empty prompt rejection
- `test_invalid_duration`: Duration validation
- `test_disk_full_simulation`: Disk space handling
- `test_cuda_unavailable_cpu_fallback`: CPU fallback
- `test_corrupted_audio_tensor`: Corrupted data handling
- `test_missing_pyloudnorm`: Dependency fallback

**Run**:
```bash
pytest tests/integration/test_error_scenarios.py -v
```

---

### 4. test_performance.py (8 tests)

**Purpose**: Performance benchmarking and optimization validation

**Test Classes**:
- `TestGenerationLatency`: Generation time benchmarks
- `TestAPIResponseTime`: API response performance
- `TestMemoryUsage`: Memory usage validation
- `TestFileIOPerformance`: File I/O performance
- `TestConcurrentOperations`: Concurrent operation performance
- `TestPerformanceReport`: Comprehensive performance reporting

**Key Tests**:
- `test_16s_generation_under_30s`: MVP target validation
- `test_database_query_performance`: Query time (<100ms)
- `test_gpu_memory_under_budget`: Memory budget (<30GB)
- `test_wav_export_performance`: Export time
- `test_generate_performance_report`: Full benchmark report

**Performance Baselines**:
- Generation latency: <30s for 16s audio (GPU)
- API response: <100ms for status endpoints
- Memory peak: <30GB during generation
- Database queries: <100ms
- Test suite: <5 minutes total

**Run**:
```bash
pytest tests/integration/test_performance.py -v -m slow
```

---

### 5. test_database_consistency.py (10 tests)

**Purpose**: Database consistency and integrity validation

**Test Classes**:
- `TestDatabaseIntegrity`: Integrity checks
- `TestTransactionHandling`: Transaction rollback
- `TestOrphanedData`: Orphaned file/record detection
- `TestDatabaseQueries`: Query correctness
- `TestMetadataConsistency`: Metadata storage
- `TestConcurrentAccess`: Concurrent access handling
- `TestConsistencyReport`: Consistency reporting

**Key Tests**:
- `test_all_generations_have_database_records`: File/DB sync
- `test_transaction_rollback_on_failure`: Rollback handling
- `test_detect_orphaned_files`: Orphan detection
- `test_query_performance_with_many_records`: Query performance
- `test_metadata_json_structure`: Metadata validation
- `test_comprehensive_consistency_check`: Full consistency check

**Run**:
```bash
pytest tests/integration/test_database_consistency.py -v
```

---

## Test Utilities

### audio_helpers.py

Audio validation and quality measurement utilities.

**Key Functions**:
- `validate_wav_file()`: Validate WAV format compliance
- `measure_loudness()`: Measure LUFS loudness
- `check_no_clipping()`: Detect audio clipping
- `verify_audio_quality()`: Comprehensive quality check
- `compare_audio_properties()`: Compare properties
- `create_test_audio_tensor()`: Generate test audio

### db_helpers.py

Database testing and seeding utilities.

**Key Functions**:
- `seed_test_generations()`: Seed test data
- `verify_database_consistency()`: Check consistency
- `get_orphaned_files()`: Find orphaned files
- `get_orphaned_records()`: Find orphaned records
- `create_generation_with_file()`: Create with file
- `cleanup_test_files()`: Clean up test files

### mock_helpers.py

Mock implementations for fast testing without GPU.

**Key Classes/Functions**:
- `MockMusicGenerationEngine`: Fast mock engine
- `create_mock_audio_tensor()`: Mock audio generation
- `mock_generation_failure()`: Mock failure
- `mock_generation_success()`: Mock success

---

## Coverage Reports

### Running Coverage Analysis

```bash
# Generate HTML coverage report
pytest tests/integration/ --cov=services --cov-report=html --cov-report=term

# View HTML report
open htmlcov/index.html
```

### Coverage Targets

| Module | Target | Current |
|--------|--------|---------|
| services/generation/ | 90%+ | TBD |
| services/storage/ | 94%+ | 94% |
| services/audio/ | 90%+ | TBD |
| Overall | 92%+ | TBD |

### Interpreting Coverage Reports

1. **Green lines**: Executed during tests
2. **Red lines**: Not executed (need more tests)
3. **Yellow lines**: Partial execution (branches)
4. **Missing lines**: Priority for additional tests

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-cov
      - name: Run integration tests
        run: |
          pytest tests/integration/ -v -m "not gpu and not slow" --cov=services
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### GitLab CI Example

```yaml
integration_tests:
  stage: test
  script:
    - pip install -r requirements.txt
    - pip install pytest pytest-cov
    - pytest tests/integration/ -v -m "not gpu" --cov=services
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

---

## Performance Benchmarks

### Baseline Metrics (Mock Engine)

| Metric | Target | Typical |
|--------|--------|---------|
| 16s audio generation | <30s | <1s (mock) |
| Database query (10 records) | <100ms | <10ms |
| WAV export (16s) | <1s | <100ms |
| Metadata extraction | <5s | <500ms |
| Full test suite | <5min | ~2min |

### Real Engine Benchmarks (GPU Required)

| Metric | Target | Acceptable |
|--------|--------|-----------|
| 16s audio generation | <30s | <60s |
| Peak GPU memory | <20GB | <30GB |
| Real-time factor | <2x | <4x |

### Running Performance Tests

```bash
# Run performance tests with report generation
pytest tests/integration/test_performance.py -v -s

# Results written to: tmp/performance_report.json
```

---

## Troubleshooting

### Common Issues

**1. CUDA Not Available**

```
CUDA not available - skipping GPU tests
```

**Solution**: GPU tests are automatically skipped. Use mock engine for testing without GPU.

**2. Import Errors**

```
ModuleNotFoundError: No module named 'services'
```

**Solution**: Run tests from project root or set PYTHONPATH:
```bash
export PYTHONPATH=/home/beengud/raibid-labs/dgx-music:$PYTHONPATH
pytest tests/integration/ -v
```

**3. Database Locked**

```
sqlite3.OperationalError: database is locked
```

**Solution**: Close other connections or use separate test database:
```bash
export DATABASE_URL=sqlite:///data/test.db
pytest tests/integration/ -v
```

**4. Missing Dependencies**

```
ImportError: pyloudnorm not available
```

**Solution**: Install optional dependencies:
```bash
pip install pyloudnorm librosa
```

### Debug Mode

```bash
# Run with verbose output and debug logging
pytest tests/integration/ -v -s --log-cli-level=DEBUG

# Run single test with full traceback
pytest tests/integration/test_e2e_complete.py::TestCompleteWorkflow::test_simple_generation_to_database -vv
```

---

## Best Practices

### Writing New Tests

1. **Use fixtures**: Leverage shared fixtures in `conftest.py`
2. **Mock when possible**: Use `mock_engine` for speed
3. **Clean up**: Tests should clean up their artifacts
4. **Descriptive names**: Test names should describe behavior
5. **Assertions**: Use descriptive assertion messages

### Test Organization

1. **Group related tests**: Use test classes
2. **Mark appropriately**: Use `@pytest.mark` for categorization
3. **Keep tests independent**: No test should depend on another
4. **Fast by default**: Use GPU/slow tests sparingly

### Example Test Template

```python
import pytest
from pathlib import Path

pytestmark = pytest.mark.integration


class TestMyFeature:
    """Test my new feature."""

    def test_basic_functionality(self, mock_engine, mock_settings):
        """Test basic functionality works."""
        # Arrange
        request = GenerationRequest(prompt="test", duration=2.0)

        # Act
        result = mock_engine.generate(request)

        # Assert
        assert result.status == "completed"
        assert Path(result.file_path).exists()
```

---

## Advanced Testing

### Property-Based Testing

```bash
pip install hypothesis

# Example in test file
from hypothesis import given, strategies as st

@given(st.floats(min_value=0.5, max_value=30.0))
def test_any_valid_duration(duration, mock_engine):
    request = GenerationRequest(prompt="test", duration=duration)
    result = mock_engine.generate(request)
    assert result.status == "completed"
```

### Mutation Testing

```bash
pip install mutmut

# Run mutation testing
mutmut run --paths-to-mutate=services/
mutmut results
```

### Load Testing

```bash
pip install locust

# Create locustfile.py for API load testing
locust -f tests/load/locustfile.py --host=http://localhost:8000
```

---

## Continuous Improvement

### Coverage Goals

- **Week 1-2**: 85%+ coverage (foundation)
- **Week 3-4**: 90%+ coverage (optimization)
- **Week 5-6**: 92%+ coverage (production)

### Test Metrics

Track these metrics over time:
- Test count
- Coverage percentage
- Test execution time
- Flaky test count
- Bug escape rate

### Review Checklist

Before merging new code:
- [ ] All tests pass
- [ ] Coverage >90%
- [ ] No new flaky tests
- [ ] Performance benchmarks met
- [ ] Documentation updated

---

## Resources

### Documentation
- [Pytest Documentation](https://docs.pytest.org/)
- [Coverage.py Documentation](https://coverage.readthedocs.io/)
- [Testing Best Practices](https://docs.python.org/3/library/unittest.html)

### Project Documentation
- `README.md`: Project overview
- `CLAUDE.md`: Development guide
- `PROJECT_STATUS.md`: Current status
- `docs/database-schema.md`: Database design

### Support

For questions or issues:
1. Check this guide
2. Review existing tests
3. Check test output/logs
4. Consult project documentation

---

**Last Updated**: November 7, 2025
**Test Suite Version**: 1.0
**Document Owner**: Engineering Team
