# Workstream 2: Test Plan

**Version**: 1.0
**Created**: November 7, 2025
**Status**: Active

---

## Test Strategy

### Testing Levels

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test component interactions with real database
3. **System Tests**: End-to-end testing with full stack
4. **Performance Tests**: Validate performance targets

### Coverage Targets

- **Unit Tests**: 95%+ coverage
- **Integration Tests**: 90%+ coverage
- **Overall**: 90%+ coverage

---

## Week 1: Database Foundation

### Unit Tests (`tests/unit/test_models.py`)

#### Generation Model Tests

| Test | Purpose | Status |
|------|---------|--------|
| `test_generation_creation` | Verify model instantiation | ✅ PASS |
| `test_generation_default_values` | Check default field values | ✅ PASS |
| `test_generation_uuid_id` | Validate UUID generation | ✅ PASS |
| `test_is_pending` | Test pending status check | ✅ PASS |
| `test_is_processing` | Test processing status check | ✅ PASS |
| `test_is_complete` | Test completed status check | ✅ PASS |
| `test_is_failed` | Test failed status check | ✅ PASS |
| `test_get_metadata_empty` | Handle empty metadata | ✅ PASS |
| `test_set_and_get_metadata` | Metadata round-trip | ✅ PASS |
| `test_metadata_json_serialization` | JSON storage validation | ✅ PASS |
| `test_mark_processing` | Status transition to processing | ✅ PASS |
| `test_mark_completed` | Status transition to completed | ✅ PASS |
| `test_mark_failed` | Status transition to failed | ✅ PASS |
| `test_to_dict` | Dictionary conversion | ✅ PASS |
| `test_repr` | String representation | ✅ PASS |

**Total**: 15 tests
**Status**: ✅ 15/15 PASS

#### Prompt Model Tests

| Test | Purpose | Status |
|------|---------|--------|
| `test_prompt_creation` | Verify model instantiation | ✅ PASS |
| `test_prompt_default_values` | Check default field values | ✅ PASS |
| `test_increment_usage` | Usage counter increment | ✅ PASS |
| `test_increment_usage_multiple_times` | Multiple increments | ✅ PASS |
| `test_to_dict` | Dictionary conversion | ✅ PASS |
| `test_repr` | String representation | ✅ PASS |

**Total**: 6 tests
**Status**: ✅ 6/6 PASS

### Integration Tests (`tests/integration/test_database.py`)

#### Database Initialization Tests

| Test | Purpose | Status |
|------|---------|--------|
| `test_init_db` | Database file creation | ✅ PASS |
| `test_get_session` | Session acquisition | ✅ PASS |

**Total**: 2 tests
**Status**: ✅ 2/2 PASS

#### Generation CRUD Tests

| Test | Purpose | Status |
|------|---------|--------|
| `test_create_generation` | Create generation record | ✅ PASS |
| `test_create_generation_with_metadata` | Create with metadata | ✅ PASS |
| `test_get_generation` | Retrieve by ID | ✅ PASS |
| `test_get_generation_not_found` | Handle missing record | ✅ PASS |
| `test_get_all_generations` | List all generations | ✅ PASS |
| `test_get_all_generations_with_limit` | Pagination with limit | ✅ PASS |
| `test_get_all_generations_with_status_filter` | Filter by status | ✅ PASS |
| `test_update_generation_status` | Update status field | ✅ PASS |
| `test_complete_generation` | Mark as completed | ✅ PASS |
| `test_delete_generation` | Delete record | ✅ PASS |
| `test_delete_generation_not_found` | Delete non-existent | ✅ PASS |
| `test_get_pending_generations` | Filter pending jobs | ✅ PASS |
| `test_count_generations` | Count records | ✅ PASS |

**Total**: 13 tests
**Status**: ✅ 13/13 PASS

#### Prompt Tracking Tests

| Test | Purpose | Status |
|------|---------|--------|
| `test_track_prompt_usage_new` | Create new prompt | ✅ PASS |
| `test_track_prompt_usage_existing` | Increment existing prompt | ✅ PASS |
| `test_prompt_tracking_with_generation` | Auto-tracking on create | ✅ PASS |
| `test_get_most_used_prompts` | Popular prompts query | ✅ PASS |

**Total**: 4 tests
**Status**: ✅ 4/4 PASS

#### Statistics Tests

| Test | Purpose | Status |
|------|---------|--------|
| `test_get_database_stats` | Database statistics | ✅ PASS |

**Total**: 1 test
**Status**: ✅ 1/1 PASS

#### Transaction Tests

| Test | Purpose | Status |
|------|---------|--------|
| `test_session_commit_on_success` | Auto-commit on success | ✅ PASS |
| `test_session_rollback_on_error` | Auto-rollback on error | ✅ PASS |

**Total**: 2 tests
**Status**: ✅ 2/2 PASS

### Week 1 Summary

| Category | Tests | Pass | Fail | Coverage |
|----------|-------|------|------|----------|
| Unit Tests | 21 | 21 | 0 | 95% |
| Integration Tests | 22 | 22 | 0 | 90% |
| **Total** | **43** | **43** | **0** | **94%** |

**Status**: ✅ **ALL TESTS PASSING**

---

## Week 2: Audio Export (Planned)

### Unit Tests (Planned)

#### Audio Export Tests
- `test_tensor_to_wav_conversion` - PyTorch tensor to WAV
- `test_wav_file_creation` - File creation
- `test_audio_normalization` - Loudness normalization
- `test_sample_rate_conversion` - Sample rate handling
- `test_metadata_extraction` - Duration, channels extraction

#### File Management Tests
- `test_file_path_generation` - UUID-based paths
- `test_directory_creation` - Output directory setup
- `test_file_cleanup` - Cleanup utilities
- `test_storage_statistics` - Disk usage tracking

### Integration Tests (Planned)

#### End-to-End Export Tests
- `test_export_pipeline` - Full export workflow
- `test_export_with_normalization` - Export with loudness norm
- `test_batch_export` - Multiple file export
- `test_export_error_handling` - Error scenarios

#### WS1 Integration Tests
- `test_generation_to_export` - Generation → Export flow
- `test_database_update_after_export` - Metadata update
- `test_concurrent_exports` - Parallel export handling

**Estimated**: 15-20 additional tests

---

## Week 3: Ardour Integration (Planned)

### Unit Tests (Planned)

#### Ardour Template Tests
- `test_template_generation` - XML template creation
- `test_track_configuration` - Track setup
- `test_region_placement` - Audio region placement
- `test_session_metadata` - Session info

### Integration Tests (Planned)

#### Template Export Tests
- `test_export_to_ardour` - Full export workflow
- `test_ardour_import` - Validate Ardour can open
- `test_multi_track_export` - Multiple generations

**Estimated**: 8-10 additional tests

---

## Performance Tests

### Database Performance

#### Load Tests
- Insert 1000 generations: Target <5 seconds
- Query 1000 generations: Target <100ms
- Update 100 generations: Target <500ms

#### Concurrent Access
- 10 concurrent sessions: No deadlocks
- 100 parallel queries: <200ms average

### Audio Export Performance

#### Export Benchmarks
- 16s audio export: Target <2 seconds
- Normalization: Target <1 second
- Batch export (10 files): Target <20 seconds

---

## Test Execution

### Running Tests

#### All Tests
```bash
pytest tests/ -v
```

#### Unit Tests Only
```bash
pytest tests/unit/ -v
```

#### Integration Tests Only
```bash
pytest tests/integration/ -v
```

#### With Coverage
```bash
pytest tests/ --cov=services.storage --cov-report=html
```

#### Specific Test
```bash
pytest tests/unit/test_models.py::TestGeneration::test_generation_creation -v
```

### Continuous Integration

#### Pre-commit Checks
```bash
just quality  # Lint + typecheck
just test     # All tests
```

#### CI Pipeline (Planned)
1. Lint (ruff)
2. Type check (mypy)
3. Unit tests
4. Integration tests
5. Coverage report
6. Performance benchmarks

---

## Test Data Fixtures

### Generation Fixtures

```python
@pytest.fixture
def sample_generation():
    return {
        "prompt": "hip hop beat at 140 BPM",
        "model_name": "musicgen-small",
        "duration_seconds": 16.0,
        "sample_rate": 32000,
        "channels": 2,
        "file_path": "outputs/test.wav"
    }

@pytest.fixture
def completed_generation():
    gen = Generation(**sample_generation)
    gen.mark_completed(18.5)
    gen.file_size_bytes = 5242880
    gen.set_metadata({"bpm": 140, "key": "Cm"})
    return gen
```

### Database Fixtures

```python
@pytest.fixture
def test_db():
    """Create temporary test database."""
    temp_fd, temp_path = tempfile.mkstemp(suffix=".db")
    os.close(temp_fd)
    init_db(f"sqlite:///{temp_path}")
    yield temp_path
    os.unlink(temp_path)
```

---

## Test Environment

### Dependencies

```
pytest>=8.0.0
pytest-cov>=4.1.0
pytest-asyncio>=0.23.0
httpx>=0.27.0
```

### Configuration

**File**: `pytest.ini`

```ini
[pytest]
python_files = test_*.py
python_classes = Test*
python_functions = test_*
testpaths = tests
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Slow tests
    gpu: GPU-required tests
```

---

## Coverage Reports

### Current Coverage (Week 1)

```
Name                              Stmts   Miss  Cover
-----------------------------------------------------
services/storage/__init__.py         15      0   100%
services/storage/schema.py           25      1    96%
services/storage/models.py          120      5    96%
services/storage/database.py        180     15    92%
-----------------------------------------------------
TOTAL                               340     21    94%
```

### Coverage Targets

- Week 1: 90%+ ✅ Achieved 94%
- Week 2: 90%+ (with audio export)
- Week 3: 90%+ (with Ardour integration)
- Overall: 90%+ for storage service

---

## Quality Metrics

### Code Quality Checklist

- ✅ All public functions have docstrings
- ✅ All functions have type hints
- ✅ All edge cases have tests
- ✅ Error handling is tested
- ✅ Documentation is up to date
- ✅ No linting errors (ruff)
- ✅ Type checking passes (mypy)

### Test Quality Checklist

- ✅ Tests are independent
- ✅ Tests use fixtures appropriately
- ✅ Tests have clear names
- ✅ Tests have assertions
- ✅ Tests clean up resources
- ✅ Tests are fast (<1s each for unit tests)

---

## Known Issues

### Week 1

No known issues. All tests passing.

### Future Considerations

1. **Async tests**: Consider pytest-asyncio for async database operations
2. **Performance tests**: Add benchmarking suite
3. **Load tests**: Test with large datasets (10k+ generations)
4. **Concurrent access**: More comprehensive multi-threading tests

---

## Test Maintenance

### Adding New Tests

1. Create test file in appropriate directory (`unit/` or `integration/`)
2. Use existing fixtures where possible
3. Follow naming convention: `test_<functionality>`
4. Add docstring explaining test purpose
5. Ensure test is independent
6. Run test locally before committing
7. Update this test plan

### Updating Tests

1. Run existing tests to ensure they still pass
2. Update test if API changes
3. Update docstring if behavior changes
4. Update this test plan if coverage changes

### Removing Tests

1. Document reason for removal
2. Ensure coverage doesn't drop
3. Update this test plan

---

## Continuous Improvement

### Test Review Schedule

- **Weekly**: Review failed tests
- **Bi-weekly**: Review coverage reports
- **Monthly**: Review test performance
- **Quarterly**: Update test strategy

### Metrics to Track

1. Test count by type
2. Coverage percentage
3. Test execution time
4. Flaky test rate
5. Bug detection rate

---

## Appendix: Test Commands Reference

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=services --cov-report=html

# Run specific test class
pytest tests/unit/test_models.py::TestGeneration -v

# Run specific test
pytest tests/unit/test_models.py::TestGeneration::test_generation_creation -v

# Run with markers
pytest tests/ -v -m unit
pytest tests/ -v -m integration
pytest tests/ -v -m "not slow"

# Run with verbose output
pytest tests/ -vv

# Run and stop on first failure
pytest tests/ -x

# Run and show local variables on failure
pytest tests/ -l

# Run with coverage and open HTML report
pytest tests/ --cov=services --cov-report=html && open htmlcov/index.html
```

---

**Document Version**: 1.0
**Last Updated**: November 7, 2025
**Next Review**: Week 2 completion
