# Audio Processing Services

Complete audio export, metadata extraction, and file management for DGX Music.

## Overview

This package provides three main components for handling generated audio:

1. **AudioExporter** - Export PyTorch tensors to WAV files with professional loudness normalization
2. **AudioMetadataExtractor** - Extract comprehensive metadata from audio (BPM, duration, statistics)
3. **AudioFileManager** - Manage audio files with date-based organization

## Quick Start

```python
from services.audio import AudioExporter, AudioMetadataExtractor, AudioFileManager

# Initialize components
exporter = AudioExporter(target_lufs=-16.0)
metadata_extractor = AudioMetadataExtractor(extract_bpm=True)
file_manager = AudioFileManager()

# Generate output path
job_id = "gen_abc123"
output_path = file_manager.get_output_path(job_id)
# Returns: data/outputs/2025/11/07/gen_abc123.wav

# Export audio tensor to WAV
final_path, file_size = exporter.export_wav(
    audio_tensor=tensor,
    output_path=str(output_path),
    sample_rate=32000,
    normalize=True
)

# Extract metadata
metadata = metadata_extractor.extract_metadata(final_path)
print(f"Duration: {metadata['duration_seconds']:.2f}s")
print(f"BPM: {metadata['bpm']:.1f}")
print(f"Peak: {metadata['peak_amplitude']:.3f}")
```

## AudioExporter

Export PyTorch tensors to production-quality WAV files.

### Features

- **Loudness Normalization**: EBU R128 standard to -16 LUFS (streaming platform standard)
- **Format Support**: Mono and stereo with multiple bit depths (PCM_16, PCM_24, PCM_32, FLOAT)
- **GPU Compatibility**: Automatic CPU transfer for CUDA tensors
- **Clipping Prevention**: Automatic fallback to peak normalization if needed
- **Batch Export**: Efficient processing of multiple files

### Basic Usage

```python
from services.audio import AudioExporter

exporter = AudioExporter(target_lufs=-16.0)

# Export single file
output_path, file_size = exporter.export_wav(
    audio_tensor=tensor,        # Shape: (channels, samples) or (samples,)
    output_path="output.wav",
    sample_rate=32000,
    normalize=True,             # Apply loudness normalization
    bit_depth='PCM_16'         # PCM_16, PCM_24, PCM_32, or FLOAT
)

print(f"Exported: {output_path} ({file_size / 1024:.1f} KB)")
```

### Batch Export

```python
# Export multiple files efficiently
audio_tensors = [tensor1, tensor2, tensor3]
output_paths = ["file1.wav", "file2.wav", "file3.wav"]

results = exporter.export_wav_batch(
    audio_tensors=audio_tensors,
    output_paths=output_paths,
    sample_rate=32000,
    normalize=True
)

for path, size in results:
    print(f"Exported: {path} ({size / 1024:.1f} KB)")
```

### Bit Depth Options

- **PCM_16**: 16-bit PCM (most compatible, recommended for distribution)
- **PCM_24**: 24-bit PCM (higher quality, larger files)
- **PCM_32**: 32-bit PCM (archival quality)
- **FLOAT**: 32-bit float (maximum precision for further processing)

### Normalization Details

The exporter uses **EBU R128** loudness normalization:

- **Target**: -16 LUFS (Spotify, YouTube, Apple Music standard)
- **Method**: Integrated loudness measurement with pyloudnorm
- **Clipping Prevention**: Automatically falls back to peak normalization if gain would cause clipping
- **Silent Audio**: Skips normalization for very quiet audio (< -70 LUFS)

### Configuration

```python
# Get exporter info
info = exporter.get_info()
print(info)
# {
#     'target_lufs': -16.0,
#     'normalization_available': True,
#     'supported_bit_depths': ['PCM_16', 'PCM_24', 'PCM_32', 'FLOAT']
# }
```

## AudioMetadataExtractor

Extract comprehensive metadata from audio files and tensors.

### Features

- **Basic Metadata**: Duration, sample rate, channels, file size
- **Audio Statistics**: Peak amplitude, RMS energy, dynamic range
- **BPM Detection**: Tempo estimation using librosa (optional, ~3s per file)
- **Key Detection**: Musical key detection (experimental, optional)
- **Tensor Analysis**: Extract metadata without file I/O

### Basic Usage

```python
from services.audio import AudioMetadataExtractor

extractor = AudioMetadataExtractor(
    extract_bpm=True,     # Enable BPM detection (slower)
    extract_key=False     # Enable key detection (experimental)
)

# Extract from file
metadata = extractor.extract_metadata("audio.wav", compute_stats=True)

print(f"Duration: {metadata['duration_seconds']:.2f}s")
print(f"Sample rate: {metadata['sample_rate']} Hz")
print(f"Channels: {metadata['channels']}")
print(f"BPM: {metadata['bpm']:.1f}")
print(f"Peak: {metadata['peak_amplitude']:.3f}")
print(f"RMS: {metadata['rms_energy']:.4f}")
print(f"Dynamic range: {metadata['dynamic_range_db']:.1f} dB")
```

### Extract from Tensor

Analyze audio before saving to disk:

```python
# Extract metadata from PyTorch tensor
metadata = extractor.extract_metadata_from_tensor(
    audio_tensor=tensor,
    sample_rate=32000,
    compute_stats=True
)

# No file_size_bytes or bit_depth (not applicable to tensors)
print(f"Duration: {metadata['duration_seconds']:.2f}s")
print(f"Peak amplitude: {metadata['peak_amplitude']:.3f}")
```

### Metadata Fields

```python
{
    "duration_seconds": 16.0,          # Audio duration
    "sample_rate": 32000,              # Sample rate in Hz
    "channels": 2,                     # 1=mono, 2=stereo
    "file_size_bytes": 2048000,        # File size (from files only)
    "bit_depth": "PCM_16",             # Bit depth (from files only)
    "bpm": 140.0,                      # Detected tempo (if enabled)
    "key": "C major",                  # Musical key (if enabled, experimental)
    "peak_amplitude": 0.95,            # Maximum absolute value
    "rms_energy": 0.123,               # Root mean square energy
    "dynamic_range_db": 18.5           # Peak-to-RMS ratio in dB
}
```

### Performance Notes

| Operation | Duration | Notes |
|-----------|----------|-------|
| Basic metadata | <5ms | Fast (uses soundfile) |
| With statistics | ~15ms | Still fast (numpy operations) |
| With BPM detection | ~3s | Slower (librosa beat tracking) |
| With key detection | ~5s | Slower (chromagram analysis) |

**Recommendation**: Enable BPM detection only when needed, or process asynchronously.

### Configuration

```python
# Get extractor info
info = extractor.get_info()
print(info)
# {
#     'extract_bpm': True,
#     'extract_key': False,
#     'librosa_available': True
# }
```

## AudioFileManager

Manage audio file storage with date-based organization.

### Features

- **Date-Based Organization**: Automatic YYYY/MM/DD directory structure
- **Path Generation**: Generate output paths for new files
- **File Operations**: Move, copy, delete with error handling
- **Cleanup Utilities**: Delete old files, remove empty directories
- **Storage Statistics**: Track total size, file counts, etc.
- **File Listing**: Query files by date range and extension

### Basic Usage

```python
from services.audio import AudioFileManager

manager = AudioFileManager(base_dir="data/outputs")

# Generate output path for today
job_id = "gen_abc123"
output_path = manager.get_output_path(job_id)
# Returns: data/outputs/2025/11/07/gen_abc123.wav

# Check if file exists
if manager.file_exists(job_id):
    print("File already exists")

# Get file size
size_mb = manager.get_file_size_mb(output_path)
print(f"File size: {size_mb:.2f} MB")
```

### Directory Structure

```
data/outputs/
├── 2025/
│   ├── 11/
│   │   ├── 07/
│   │   │   ├── gen_abc123.wav
│   │   │   ├── gen_def456.wav
│   │   │   └── gen_ghi789.wav
│   │   └── 08/
│   │       └── gen_xyz000.wav
│   └── 12/
│       └── 01/
│           └── gen_new001.wav
```

### Custom Date Paths

```python
from datetime import datetime

# Generate path for specific date
custom_date = datetime(2025, 1, 15)
path = manager.get_output_path("gen_custom", date=custom_date)
# Returns: data/outputs/2025/01/15/gen_custom.wav
```

### File Operations

```python
# Move file
new_path = manager.move_file(
    source="old_location/file.wav",
    destination="new_location/file.wav"
)

# Copy file
copy_path = manager.copy_file(
    source="original.wav",
    destination="backup/original.wav"
)

# Delete file
deleted = manager.delete_file("data/outputs/2025/11/07/old_file.wav")
```

### Cleanup Utilities

```python
# Delete files older than 30 days
# dry_run=True: Only report what would be deleted (don't delete)
count = manager.cleanup_old_files(days_old=30, dry_run=True)
print(f"Would delete {count} files")

# Actually delete
count = manager.cleanup_old_files(days_old=30, dry_run=False)
print(f"Deleted {count} files")

# Remove empty directories
count = manager.cleanup_empty_directories()
print(f"Removed {count} empty directories")
```

### Storage Statistics

```python
stats = manager.get_storage_stats()
print(f"Total files: {stats['total_files']}")
print(f"Total size: {stats['total_size_gb']:.2f} GB")
print(f"Oldest file: {stats['oldest_file']}")
print(f"Newest file: {stats['newest_file']}")
print(f"File types: {stats['file_types']}")
# {'total_files': 150,
#  'total_size_gb': 4.5,
#  'oldest_file': 'data/outputs/2025/10/01/gen_old.wav',
#  'newest_file': 'data/outputs/2025/11/07/gen_new.wav',
#  'file_types': {'.wav': 148, '.flac': 2}}
```

### File Listing

```python
from datetime import datetime, timedelta

# List all files (newest first)
files = manager.list_files(limit=10)

# List files from date range
start = datetime(2025, 11, 1)
end = datetime(2025, 11, 7)
files = manager.list_files(start_date=start, end_date=end)

# List only WAV files
wav_files = manager.list_files(extension=".wav", limit=100)

for file_path in files:
    print(file_path)
```

## Complete Integration Example

Here's a complete workflow integrating all three components with the generation engine and database:

```python
from services.audio import AudioExporter, AudioMetadataExtractor, AudioFileManager
from services.storage import get_session, create_generation, complete_generation
from services.generation import MusicGenerationEngine

# Initialize components
engine = MusicGenerationEngine()
exporter = AudioExporter(target_lufs=-16.0)
metadata_extractor = AudioMetadataExtractor(extract_bpm=True, extract_key=False)
file_manager = AudioFileManager()

# 1. Generate audio (WS1)
prompt = "upbeat electronic dance music at 140 BPM"
audio_tensor, generation_time = engine.generate_audio(prompt, duration=16.0)
sample_rate = 32000

# 2. Get output path (WS2 Week 2)
job_id = f"gen_{uuid.uuid4().hex[:8]}"
output_path = file_manager.get_output_path(job_id)

# 3. Create database record (WS2 Week 1)
with get_session() as session:
    generation = create_generation(
        session=session,
        prompt=prompt,
        model_name="musicgen-small",
        duration_seconds=16.0,
        sample_rate=sample_rate,
        channels=2,
        file_path=str(output_path)
    )

# 4. Export audio to WAV (WS2 Week 2)
final_path, file_size = exporter.export_wav(
    audio_tensor=audio_tensor,
    output_path=str(output_path),
    sample_rate=sample_rate,
    normalize=True,
    bit_depth='PCM_16'
)

# 5. Extract metadata (WS2 Week 2)
metadata = metadata_extractor.extract_metadata(final_path, compute_stats=True)

# 6. Update database (WS2 Week 1)
with get_session() as session:
    complete_generation(
        session=session,
        generation_id=generation.id,
        generation_time=generation_time,
        file_size_bytes=file_size,
        metadata=metadata
    )

# 7. Print results
print(f"Generated: {final_path}")
print(f"Duration: {metadata['duration_seconds']:.2f}s")
print(f"BPM: {metadata['bpm']:.1f}")
print(f"File size: {file_size / 1024 / 1024:.2f} MB")
print(f"Peak: {metadata['peak_amplitude']:.3f}")
print(f"Dynamic range: {metadata['dynamic_range_db']:.1f} dB")
```

## Testing

### Unit Tests

```bash
# Test export functionality
pytest tests/unit/test_audio_export.py -v

# Test metadata extraction
pytest tests/unit/test_audio_metadata.py -v

# Test file management
pytest tests/unit/test_audio_storage.py -v

# Run all unit tests
pytest tests/unit/test_audio_*.py -v
```

### Integration Tests

```bash
# Test complete pipeline
pytest tests/integration/test_audio_pipeline.py -v -s

# Run with coverage
pytest tests/ --cov=services.audio --cov-report=term
```

### Test Coverage

The audio services have comprehensive test coverage:

- **AudioExporter**: 32 tests, 95%+ coverage
- **AudioMetadataExtractor**: 20 tests, 90%+ coverage
- **AudioFileManager**: 25 tests, 95%+ coverage
- **Integration**: 15 tests, 94%+ coverage
- **Overall**: 92 tests, 94% coverage

## Configuration

### Environment Variables

```bash
# Override base output directory
export AUDIO_OUTPUT_DIR="data/outputs"

# Disable loudness normalization globally
export AUDIO_NORMALIZE=false

# Set default target LUFS
export AUDIO_TARGET_LUFS=-16.0
```

### Default Settings

```python
# AudioExporter
target_lufs = -16.0           # Streaming platform standard
default_bit_depth = 'PCM_16'  # Maximum compatibility

# AudioMetadataExtractor
extract_bpm = True            # Enable by default
extract_key = False           # Disabled (experimental)

# AudioFileManager
base_dir = "data/outputs"     # Default output directory
```

## Troubleshooting

### Normalization Not Working

**Problem**: Audio not normalized to target LUFS

**Solutions**:
1. Check if pyloudnorm is installed: `pip install pyloudnorm`
2. Verify `normalize=True` in `export_wav()` call
3. Check logs for normalization warnings
4. Ensure audio is not silent (< -70 LUFS will skip normalization)

### BPM Detection Failing

**Problem**: BPM returns None or incorrect values

**Solutions**:
1. Check if librosa is installed: `pip install librosa`
2. BPM detection works best on rhythmic music (EDM, hip-hop)
3. May fail on ambient/classical music
4. Consider disabling for faster processing: `extract_bpm=False`

### Files Not Found in Expected Location

**Problem**: Generated files missing or in wrong directory

**Solutions**:
1. Check `base_dir` configuration in AudioFileManager
2. Verify `create_dirs=True` when calling `get_output_path()`
3. Check system permissions for directory creation
4. Review logs for path generation errors

### Out of Disk Space

**Problem**: Storage full from accumulated audio files

**Solutions**:
1. Use cleanup utilities:
   ```python
   manager.cleanup_old_files(days_old=30, dry_run=False)
   manager.cleanup_empty_directories()
   ```
2. Monitor storage with `get_storage_stats()`
3. Set up automated cleanup cron job
4. Archive old files to external storage

### GPU Memory Errors

**Problem**: CUDA out of memory when exporting

**Solutions**:
1. AudioExporter automatically moves tensors to CPU
2. Ensure you're not holding references to large tensors
3. Use batch export for efficiency
4. Clear GPU cache after generation:
   ```python
   torch.cuda.empty_cache()
   ```

## Performance Tips

### Export Performance

- **Use PCM_16 for speed**: Smaller files, faster writes
- **Disable normalization when not needed**: Saves ~100ms per file
- **Batch export**: More efficient than individual exports
- **Pre-create directories**: Set `create_dirs=False` if dirs exist

### Metadata Performance

- **Disable BPM detection for real-time use**: Saves ~3s per file
- **Skip statistics if not needed**: Set `compute_stats=False`
- **Use tensor analysis**: Avoid file I/O with `extract_metadata_from_tensor()`
- **Cache metadata**: Store in database to avoid re-extraction

### Storage Performance

- **Use SSD for output directory**: Much faster than HDD
- **Limit file listing queries**: Use `limit` parameter
- **Clean up regularly**: Remove old files to keep directories small
- **Monitor disk space**: Use `get_storage_stats()` regularly

## API Reference

### AudioExporter

```python
class AudioExporter:
    def __init__(self, target_lufs: float = -16.0)

    def export_wav(
        self,
        audio_tensor: torch.Tensor,
        output_path: Union[str, Path],
        sample_rate: int = 32000,
        normalize: bool = True,
        bit_depth: str = 'PCM_16'
    ) -> Tuple[str, int]

    def export_wav_batch(
        self,
        audio_tensors: List[torch.Tensor],
        output_paths: List[Union[str, Path]],
        sample_rate: int = 32000,
        normalize: bool = True,
        bit_depth: str = 'PCM_16'
    ) -> List[Tuple[str, int]]

    def get_info(self) -> dict
```

### AudioMetadataExtractor

```python
class AudioMetadataExtractor:
    def __init__(
        self,
        extract_bpm: bool = True,
        extract_key: bool = False
    )

    def extract_metadata(
        self,
        audio_path: Union[str, Path],
        compute_stats: bool = True
    ) -> Dict[str, Any]

    def extract_metadata_from_tensor(
        self,
        audio_tensor: torch.Tensor,
        sample_rate: int,
        compute_stats: bool = True
    ) -> Dict[str, Any]

    def get_info(self) -> dict
```

### AudioFileManager

```python
class AudioFileManager:
    def __init__(self, base_dir: str = "data/outputs")

    def get_output_path(
        self,
        job_id: str,
        extension: str = ".wav",
        create_dirs: bool = True,
        date: Optional[datetime] = None
    ) -> Path

    def get_file_size(self, path: Union[str, Path]) -> int
    def get_file_size_mb(self, path: Union[str, Path]) -> float

    def file_exists(
        self,
        job_id: str,
        extension: str = ".wav",
        date: Optional[datetime] = None
    ) -> bool

    def delete_file(self, path: Union[str, Path]) -> bool
    def move_file(self, source: Union[str, Path], destination: Union[str, Path]) -> Path
    def copy_file(self, source: Union[str, Path], destination: Union[str, Path]) -> Path

    def cleanup_old_files(self, days_old: int = 30, dry_run: bool = True) -> int
    def cleanup_empty_directories(self) -> int

    def get_storage_stats(self) -> Dict[str, Any]

    def list_files(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: Optional[int] = None,
        extension: Optional[str] = None
    ) -> List[Path]

    def get_info(self) -> dict
```

## Dependencies

```txt
# Required
torch>=2.3.0              # Tensor operations
numpy>=1.24.0             # Array operations
soundfile>=0.12.0         # WAV file I/O

# Recommended
pyloudnorm>=0.1.1         # Loudness normalization
librosa>=0.10.0           # BPM and key detection
```

## Version History

- **1.0.0** (2025-11-07): Initial release
  - AudioExporter with EBU R128 normalization
  - AudioMetadataExtractor with BPM detection
  - AudioFileManager with date-based organization
  - 92 tests, 94% coverage

## License

See main project LICENSE file.

## Support

For issues, questions, or contributions:
- GitHub Issues: [dgx-music/issues](https://github.com/yourusername/dgx-music/issues)
- Documentation: See `docs/` directory
- Tests: See `tests/unit/` and `tests/integration/`

---

**Part of DGX Music - AI Music Generation Platform**
