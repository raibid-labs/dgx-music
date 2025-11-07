# Cutting-Edge Open Source Music Generation & Editing Tools (2024-2025)

**Research Date**: November 6, 2025
**Focus**: Production-ready open source music AI for Linux/ARM (DGX Spark)
**Target Integration**: Ardour DAW

---

## Executive Summary

### Major Breakthroughs in 2024-2025

The music AI landscape has transformed dramatically with three flagship open source models:

1. **YuE** (Apache 2.0, Jan 2025) - Full song generation like Suno.ai, but open
2. **DiffRhythm** (Apache 2.0, Mar 2025) - 4m45s songs in 10 seconds
3. **JASCO** (Meta, Nov 2024) - Chord/drum/melody-conditioned generation

**Key Trend**: Shift from 10-30 second clips to full-length song generation with commercial-friendly licenses.

### ARM/Linux Compatibility Status

- **Excellent**: DGX Spark (GB10 Grace Blackwell) is ARM64-native with 128GB unified memory
- **Stable Audio Open Small**: Optimized for ARM CPUs (341M params)
- **Most PyTorch models**: Compatible with ARM64 via official PyTorch builds
- **Challenge**: Some models require CUDA (NVIDIA-specific), but DGX Spark has integrated GPU

---

## 1. Latest Music Generation Models (2024-2025)

### 1.1 YuE: Open Full-Song Music Generation Foundation Model

**GitHub**: https://github.com/multimodal-art-projection/YuE
**License**: Apache 2.0 (January 30, 2025) - **Commercial use permitted**
**Status**: Production-ready, community-supported

#### Key Capabilities
- **Full song generation** (multiple minutes) with vocals + accompaniment
- **Multi-language**: English, Mandarin, Cantonese, Japanese, Korean
- **Diverse genres**: Hip-hop, EDM, pop, rock, jazz, classical
- **Advanced features**:
  - Chain-of-thought (CoT) and in-context learning (ICL) modes
  - Dual-track and single-track audio prompting
  - Music continuation and style transfer
  - LoRA fine-tuning capability
  - Voice cloning

#### Hardware Requirements
- **Minimum**: Python 3.8+, CUDA 11.8+, PyTorch with CUDA, Flash Attention 2
- **GPU Memory**:
  - 24GB or less: Up to 2 sessions (verse + chorus)
  - Full songs: 80GB minimum (H800, A100, or multiple RTX 4090s)
- **Performance**:
  - H800: ~150 seconds for 30-second audio
  - RTX 4090: ~360 seconds for 30-second audio

#### DGX Spark Compatibility
- **Status**: Potentially compatible but requires CUDA support validation
- **Concern**: 80GB VRAM requirement exceeds single DGX Spark GPU
- **Solution**: Use session-based generation (2-session mode fits 24GB)

#### Community Tools
- **Pinokio**: Windows one-click installer
- **YuE-extend**: Google Colab, music continuation
- **YuE-UI**: Gradio interface with batch processing
- **YuEGP/YuE-exllamav2**: Quantized versions for limited VRAM

#### Commercial Use
Explicitly permitted with attribution: "YuE by HKUST/M-A-P"

---

### 1.2 DiffRhythm: Latent Diffusion Full-Song Generation

**GitHub**: https://github.com/ASLP-lab/DiffRhythm
**License**: Apache 2.0
**Status**: Production-ready (March 2025)
**HuggingFace**: https://huggingface.co/ASLP-lab/DiffRhythm

#### Revolutionary Features
- **Blazingly fast**: Generate 4m45s songs in ~10 seconds
- **Text-based style prompts** (no audio reference needed)
- **Instrumental/pure music generation** mode
- **Song continuation and editing**
- **Full-length generation** up to 285 seconds

#### Model Variants
| Model | Duration | VRAM Requirement |
|-------|----------|------------------|
| v1.2-base | 1m35s | 8GB minimum |
| v1.2-full | 4m45s | >8GB (use `--chunked`) |

#### Technical Architecture
- Latent diffusion with Stable Audio VAE (plug-and-play compatible)
- Sentence-level lyric-vocal alignment mechanism
- DiT (Diffusion Transformer) architecture

#### Installation
```bash
git clone https://github.com/ASLP-lab/DiffRhythm.git
cd DiffRhythm
pip install -r requirements.txt
sudo apt-get install espeak-ng  # For text-to-speech processing
```

#### Platform Support
- **Linux**: Primary support (shell scripts)
- **macOS**: Confirmed working (March 2025)
- **Windows**: Batch scripts available
- **Docker**: Containerization available
- **ARM64**: Not explicitly tested but PyTorch-based (likely compatible)

#### DGX Spark Compatibility
- **Status**: Likely compatible (PyTorch-based, 8GB VRAM requirement)
- **Recommendation**: Test with `--chunked` flag for memory efficiency

---

### 1.3 Meta AudioCraft Evolution (2023-2024)

**GitHub**: https://github.com/facebookresearch/audiocraft
**License**: MIT (code), CC-BY-NC 4.0 (model weights)
**Status**: Mature, actively maintained

#### Model Suite (8 models as of 2024)

##### 1. MusicGen
- **Type**: Text-to-music generation
- **Sizes**: 300M, 1.5B, 3.3B parameters
- **Capabilities**: Melodic conditioning, controllable generation
- **Requirements**: 16GB GPU for medium model

##### 2. MAGNeT (Meta's 2024 flagship)
- **Released**: November 2023 - January 2024
- **Innovation**: Non-autoregressive generation (7x faster than MusicGen)
- **Architecture**: Masked generative transformer
- **Performance**: 10-second samples in ~4 seconds
- **Training Data**: 20,000 hours licensed music
- **Models**: 300M and 1.5B parameter variants
- **Formats**: Text-to-music and text-to-audio variants

**Key Advantage**: No semantic token conditioning, no model cascading needed

##### 3. JASCO (NEW - November 2024)
- **Full Name**: Joint Audio and Symbolic Conditioning for Temporally Controlled Text-to-Music Generation
- **Breakthrough**: Chord + drum + melody conditioning
- **Models**:
  - facebook/jasco-chords-drums-400M
  - facebook/jasco-chords-drums-1B
  - facebook/jasco-chords-drums-melody-400M
  - facebook/jasco-chords-drums-melody-1B
- **Training Data**: ~16,000 hours
- **Architecture**: EnCodec + flow-matching transformer
- **Conditioning**: T5 text embeddings + low-dimensional melody/chords/audio embeddings

**Use Case**: Create songs from chord progressions and drum patterns

##### 4. MusicGen Style (2023-2024)
- **Training**: November 2023 - February 2024
- **Capabilities**: Text + style conditioning
- **Style Input**: 1.5-4.5 second audio excerpts
- **Architecture**: 1.5B parameter autoregressive transformer
- **Training Data**: 16K hours (10K proprietary + ShutterStock + Pond5)

**Use Case**: "Generate trap beat in the style of [reference audio]"

##### 5. AudioGen
- **Type**: Text-to-sound effects
- **Training**: Public sound effects
- **Use Case**: Foley, ambient sounds, production elements

##### 6. EnCodec
- **Type**: Neural audio codec
- **Role**: Audio tokenization for all other models
- **Specs**: 32kHz, 4 codebooks @ 50Hz

##### 7. Multi Band Diffusion
- **Type**: Diffusion-based EnCodec decoder
- **Purpose**: Improved audio quality

##### 8. AudioSeal
- **Type**: Audio watermarking
- **Purpose**: Track AI-generated content

#### Installation
```bash
pip install -U audiocraft
```

Requirements:
- Python 3.9
- PyTorch 2.1.0
- ffmpeg (<5 for Conda)

#### DGX Spark Compatibility
- **Status**: Compatible (standard PyTorch/CUDA requirements)
- **Recommendation**: Use MAGNeT for speed, JASCO for control

---

### 1.4 Stable Audio (Stability AI)

#### Stable Audio Open (June 2024)
**License**: Non-commercial (CC-BY-NC 4.0 equivalent)
**Capabilities**:
- Generate up to 47 seconds of audio
- Text-to-audio for sound effects and short music clips
- Fine-tunable on custom audio data

**Training**: 486,000 samples (Freesound + Free Music Archive)

**Limitations**:
- Not optimized for full songs or vocals
- Non-commercial license

#### Stable Audio Open Small (May 2025)
**Breakthrough**: First smartphone-capable audio generation AI

**Specs**:
- **Size**: 341M parameters
- **Optimized**: ARM CPUs (perfect for DGX Spark!)
- **Performance**: Generate 11 seconds of audio in <8 seconds on smartphones
- **License**: Same non-commercial restrictions

#### DGX Spark Compatibility
- **Status**: EXCELLENT - explicitly optimized for ARM
- **Recommendation**: Ideal for quick sound effects and short clips

---

### 1.5 Community Fine-Tunes & Derivatives

#### Notable Projects
1. **MusicGen Fine-Tunes** (HuggingFace Hub)
   - Genre-specific models (lo-fi, trap, house)
   - Instrument-specific models (guitar, piano)
   - Community training recipes available

2. **AudioCraft Extensions**
   - Multi-language models
   - Extended duration models
   - Custom soundfont integrations

---

## 2. MIDI Generation Advances (2024-2025)

### 2.1 Symbolic Music Transformers

#### Text2MIDI (AAAI 2025)
**Paper**: https://ojs.aaai.org/index.php/AAAI/article/view/34516
**Status**: Academic research model

**Architecture**:
- Pretrained LLM encoder for text processing
- Autoregressive transformer decoder for MIDI generation
- Trained on Lakh MIDI + MetaMIDI datasets

**Capabilities**:
- Music theory term understanding (chords, keys, tempo)
- High-quality MIDI generation from captions
- REMI (MIDI event representation) encoding

**Status**: Implementation details limited; may require retraining

---

### 2.2 Open Source MIDI Transformers (GitHub)

#### 1. SkyTNT/midi-model
**GitHub**: https://github.com/SkyTNT/midi-model
**HuggingFace**: https://huggingface.co/skytnt/midi-model
**License**: Apache 2.0
**Status**: Production-ready (2024)

**Specs**:
- 233M parameters
- MIDI event transformer
- Symbolic music generation
- Demo available on HuggingFace

#### 2. Full-MIDI-Music-Transformer (asigalov61)
**GitHub**: https://github.com/asigalov61/Full-MIDI-Music-Transformer

**Features**:
- Ultra-fast generation
- Full MIDI specification support
- Event and time counter tokens
- Complete feature set

#### 3. Piano-music-transformer-MIDI (VladPetk)
**GitHub**: https://github.com/VladPetk/Piano-music-transformer-MIDI

**Features**:
- Solo piano compositions
- Quantized output (DAW-ready)
- Pre-trained models available

#### 4. midiGPT (johnnygreco)
**GitHub**: https://github.com/johnnygreco/midiGPT

**Architecture**:
- Decoder-only transformer (GPT-style)
- From-scratch PyTorch implementation
- MIDI data generation

---

### 2.3 Music Transformer Research (2024)

**Key Developments**:
- LG AI Research: Interactive system with decoder-only autoregressive transformer
- Input: Musical metadata
- Output: 4-bar multitrack MIDI sequences
- Trained on: Lakh MIDI + MetaMIDI datasets

**Emotion-Aware AI**: 2024-2025 models compose with intentional expressiveness

**Live Performance**: Anticipatory Music Transformer performed live concert with GRAMMY-winning artist Jordan Rudess

---

## 3. Audio-to-MIDI Transcription (2024-2025)

### 3.1 Spotify Basic Pitch

**GitHub**: https://github.com/spotify/basic-pitch
**License**: Open source
**Status**: Mature (ICASSP 2022), actively maintained
**Web Demo**: https://basicpitch.spotify.com

#### Capabilities
- Lightweight polyphonic transcription (<20MB memory, <17K params)
- Pitch bend detection
- Instrument-agnostic (works on almost any instrument + voice)
- Output formats: MIDI, CSV, NPZ, sonified WAV

#### Platform Support
- **macOS, Windows, Ubuntu**
- **Python 3.7-3.11**
- **Mac M1**: Python 3.10 only
- **Runtime Options**: TensorFlow, CoreML, TensorFlowLite, ONNX

#### Installation
```bash
pip install basic-pitch
# Or with TensorFlow
pip install basic-pitch[tf]
```

#### Command-Line Usage
```bash
basic-pitch <output-dir> <input-audio>
```

#### Python API
```python
from basic_pitch import predict
from basic_pitch.inference import Model

model = Model()
model_output, midi_data, note_events = predict('audio.wav')
```

#### DGX Spark Compatibility
- **Status**: Excellent - lightweight, CPU-only option available
- **Recommendation**: Ideal for real-time transcription

---

### 3.2 NeuralNote VST Plugin

**GitHub**: https://github.com/DamRsn/NeuralNote
**License**: Open source
**Status**: Production-ready VST3/AU plugin

#### Features
- Real-time audio-to-MIDI transcription in DAW
- Based on Spotify Basic Pitch
- RTNeural-powered (efficient CPU usage)
- Split CNN architecture for real-time processing

#### Platform Support
- VST3 (Linux, Windows, macOS)
- AU (macOS)
- Standalone application

#### Community Forks
- **NeuralNotePlus** (phasedcloak): Enhanced features
- **NeuralNote-1** (isosphere): Additional modifications

#### Ardour Integration
- **Status**: Should work via VST3 (Ardour 6.0+ has VST3 support)
- **Recommendation**: Test as VST3 audio effect plugin

---

### 3.3 Demucs v4: Source Separation

**GitHub**: https://github.com/facebookresearch/demucs
**License**: MIT
**Status**: Production-ready (v4 - Hybrid Transformer)

#### Capabilities
- Separate drums, bass, vocals, other (4-source)
- 6-source model available (adds guitar, piano)
- State-of-the-art: 9.0-9.2 dB SDR on MUSDB HQ

#### Model Variants
- **htdemucs_ft**: Fine-tuned (slower, best quality)
- **htdemucs**: Standard (default, fast)
- **htdemucs_6s**: 6-source separation
- **hdemucs_mmi**: Retrained hybrid baseline
- **mdx/mdx_extra**: Additional training data

#### Installation
```bash
python3 -m pip install -U demucs
```

#### Usage
```bash
# Separate audio into stems
demucs audio.mp3

# Use specific model
demucs -n htdemucs_ft audio.mp3

# 6-source separation
demucs -n htdemucs_6s audio.mp3
```

#### Hardware Requirements
- **GPU**: 3GB VRAM minimum, 7GB for full features
- **CPU**: ~1.5x audio duration processing time

#### Platform Support
- Docker, Google Colab, HuggingFace Spaces
- Windows, macOS, Linux native
- Third-party GUIs: Demucs-GUI, Ultimate Vocal Remover

#### DGX Spark Compatibility
- **Status**: Excellent - standard PyTorch/CUDA
- **Use Case**: Pre-process audio for MIDI transcription

---

### 3.4 Polyphonic Transcription Tools (2024)

#### NeuralNote (Free)
- Built on Spotify's Basic Pitch
- Real-time transcription in DAW
- Not designed for live performance (very fast converter)

#### Samplab (Commercial, 2024)
- Free browser-based audio-to-MIDI tool
- Unique: Edit polyphonic audio as if it were MIDI
- Preserves original timbre

#### RipX DAW (Commercial)
- Local processing (no cloud)
- Strong audio-to-MIDI converter
- One-time purchase model

#### ACE Studio (Commercial, 2025)
- DAW bridge feature (early 2025)
- Works with Ableton, Logic Pro, FL Studio

#### MIREX 2024
- First-time polyphonic transcription task
- Focus: Piano transcription (audio-to-MIDI)

---

## 4. Integration Tools & DAW Automation

### 4.1 Ardour DAW (2024 Updates)

**Version**: 8.8 (October 2024)
**Website**: https://ardour.org
**License**: GPL

#### 2024-2025 Features
- Mackie Control Protocol (MCP hardware) support
- Automation for all parameters
- MIDI Learn for any control
- Sample-accurate automation
- VST3 support (6.0+)
- LV2 plugin support
- Launchpad Pro controller support

#### Automation Capabilities
- Automate any parameter
- MIDI-controlled automation
- Pre-defined MIDI controller mappings
- Dynamic MIDI learn

**Note**: "MCP" in Ardour context = Mackie Control Protocol (hardware), not Model Context Protocol (AI)

---

### 4.2 Carla Plugin Host

**GitHub**: https://github.com/falkTX/Carla
**Website**: https://kx.studio/Applications:Carla
**License**: GPL

#### Features
- Host VST2, VST3, LV2, LADSPA, DSSI, AU plugins
- Standalone and plugin mode
- Full automation support
- JACK integration
- Multi-plugin routing

#### ARM Compatibility (2024)
- **Status**: Supported on aarch64 (Arch Linux ARM packages available)
- **v2.5.6** (August 2023): Fixed JACK crash on Linux ARM
- **Raspberry Pi**: Successfully built and tested

#### DGX Spark Compatibility
- **Status**: Excellent - active ARM64 support
- **Use Case**: Bridge VST plugins to Ardour

---

### 4.3 Linux Plugin Ecosystem

#### Plugin Formats Supported
- **LV2**: 1200+ plugins, open standard, preferred on Linux
- **VST3**: Growing Linux support (Steinberg added Linux 2017)
- **VST2/LinuxVST**: Legacy support

#### Notable Plugin Suites

##### Linux Studio Plugins (LSP)
**Website**: https://lsp-plug.in
**Formats**: LV2, VST2, VST3
**Status**: Active development (2024)

**Plugin Categories**:
- Analyzers, compressors, delays
- EQs, limiters, reverbs
- Synthesizers

##### Top Free Plugins for Linux (2024)
1. **Surge XT**: Hybrid synth (VST3/LV2)
2. **Vital**: Wavetable synth (VST3/LV2)
3. **Helm**: Bass synth, perfect for 808s
4. **ZynAddSubFX**: Versatile classic synth
5. **Odin 2**: Polyphonic synth (VST3/LV2/CLAP)

---

### 4.4 MCP Servers for Music (2024-2025)

#### MIDI MCP Server (tubone24)
**GitHub**: https://github.com/tubone24/midi-mcp-server
**Status**: Production-ready

**Tool**: `create_midi`
- Input: JSON structure (BPM, time signature, tracks, notes)
- Output: MIDI file
- Dependencies: @modelcontextprotocol/sdk, midi-writer-js, tonal

**Example JSON**:
```json
{
  "bpm": 140,
  "timeSignature": "4/4",
  "tracks": [{
    "instrument": "synth_bass_1",
    "notes": [
      {"pitch": "C2", "duration": "quarter", "time": 0},
      {"pitch": "Eb2", "duration": "quarter", "time": 1}
    ]
  }]
}
```

**DGX Spark Compatibility**: Excellent (Node.js-based)

---

## 5. Hip-Hop & EDM Specific Tools

### 5.1 Open Source 808/Bass Synthesis

#### Free VST Plugins (2024)

##### 808XD (Audiolatry)
**Type**: Free VST3
**License**: Proprietary freeware
**Features**:
- 31 presets (saturated, distorted, modulated, clean)
- Optimized for Trap, Hip Hop, EDM, Hardstyle
- Dirty, deep, aggressive basslines

##### HUM 808 XL (Cali Beat)
**Type**: Free VST
**Features**:
- Additive synthesis + FM
- 3 oscillators, 5 waveforms, 16 voices
- ADSR envelopes
- 8 dedicated modulators
- Tempo-synced modulation
- DAW tempo integration

**Comparison**: Similar to SubLab (commercial)

##### 808 Bass Module 4
**Type**: Free VST
**Features**:
- 15 presets
- ADSR, LFO, distortion controls
- Aggressive trap/hip-hop sounds

##### BD-808
**Type**: Free VST
**License**: Open source
**Description**: TR-808 Bass Drum emulation usable as bass synth

##### TAL-Bassline
**Type**: Free VST
**License**: Proprietary freeware
**Description**: Virtual analog bass synthesizer for bass, acid, effects

---

### 5.2 Open Source Drum Machine Emulations

#### Hardware Emulations

##### iO-808
**Website**: https://io808.com
**Type**: Web-based TR-808
**Tech Stack**: React, Redux, Web Audio API
**Status**: Free, open source
**Features**: Fully recreated TR-808 in browser

##### SC-808
**Type**: SuperCollider-based TR-808
**Developer**: Yoshinosuke Horiuchi
**Status**: Free download
**Platform**: Cross-platform (SuperCollider)

##### Roland 808303.studio
**Website**: https://808303.studio (Note: May be deprecated, check availability)
**Type**: Web-based TR-808 + TB-303
**Developer**: Yuri Suzuki + Roland
**Status**: Free browser access

#### Desktop Drum Machines

##### BP-909 (NEW - December 2024)
**Developer**: Bipolar Audio
**Type**: Free 909 emulation
**Formats**: VST2, VST3 (Windows), macOS coming soon
**Features**: Includes WAV samples

##### Hydrogen
**Type**: Pattern-based drum machine
**Formats**: Standalone + JACK
**Installation**: `sudo apt-get install hydrogen`
**Status**: Mature, active development

##### DrumGizmo
**Type**: High-quality drum kit player
**Formats**: VST, LV2
**Installation**: `sudo apt-get install drumgizmo`
**Features**: Realistic drum samples

---

### 5.3 Open Source Sample Datasets (2024)

#### EDM TR-909 Dataset
**Released**: August 2024
**License**: CC BY 4.0
**Content**: 3,780 drum loops
**Format**: WAV files

#### EDM TR-808 Dataset
**Released**: August 2024
**License**: CC BY 4.0
**Content**: 3,790 drum loops
**Format**: WAV files

**Use Case**: Free samples for music production, dataset for training AI models

---

### 5.4 Genre-Specific Sample Packs

#### Free Resources
- **99sounds.org**: Free sample packs
- **musical-artifacts.com**: Community-uploaded samples, SoundFonts
- **freesound.org**: CC-licensed sound effects and samples

#### Format Recommendations
- **WAV**: Lossless, DAW-compatible
- **SF2/SFZ**: SoundFont format for FluidSynth/LinuxSampler
- **REX**: For loop libraries

---

## 6. DGX Spark Deployment Considerations

### 6.1 Hardware Specifications

**NVIDIA DGX Spark**:
- **CPU**: 20-core ARM (10x Cortex-X925 + 10x Cortex-A725)
- **GPU**: NVIDIA GB10 Grace Blackwell Superchip (integrated)
- **RAM**: 128GB LPDDR5x unified memory
- **Storage**: 4TB SSD
- **Architecture**: ARM64 (aarch64)

### 6.2 Software Ecosystem

**Pre-installed**:
- NVIDIA AI software stack
- NGC CLI (ARM64 version)
- Support for models up to 200B parameters

**Deployment Capabilities**:
- Local prototyping and fine-tuning
- Inference of reasoning AI models (DeepSeek, Meta, Google)
- Seamless datacenter/cloud deployment

### 6.3 Music AI Compatibility Matrix

| Tool | DGX Spark Compatibility | Notes |
|------|-------------------------|-------|
| **YuE** | Moderate | Requires 80GB VRAM (use session mode) |
| **DiffRhythm** | Good | 8GB VRAM, PyTorch-based |
| **AudioCraft** | Good | Standard CUDA requirements |
| **Stable Audio Open Small** | Excellent | ARM-optimized |
| **Basic Pitch** | Excellent | Lightweight, CPU-only option |
| **Demucs** | Good | 3-7GB VRAM |
| **Carla** | Excellent | Active ARM64 support |
| **FluidSynth** | Excellent | CPU-only, standard Linux |
| **MIDI Transformers** | Good | PyTorch-based, minimal VRAM |

### 6.4 Recommended Deployment Strategy

#### Phase 1: CPU-Based Tools (Immediate)
1. **FluidSynth** - MIDI rendering
2. **Basic Pitch** - Audio-to-MIDI transcription
3. **Carla** - Plugin hosting
4. **Ardour** - DAW
5. **MIDI Transformers** - Symbolic generation

**Advantages**: No GPU required, instant deployment

#### Phase 2: GPU-Accelerated Tools (Testing Required)
1. **Stable Audio Open Small** - ARM-optimized, test first
2. **DiffRhythm** - 8GB VRAM requirement
3. **AudioCraft MAGNeT** - Fastest Meta model

**Testing Steps**:
1. Verify CUDA availability on DGX Spark GPU
2. Test PyTorch GPU detection: `torch.cuda.is_available()`
3. Start with smallest models
4. Monitor memory usage

#### Phase 3: Cloud Hybrid (For Heavy Models)
- **YuE full songs**: Use cloud instance (80GB VRAM)
- **Large model fine-tuning**: Datacenter deployment
- **Local inference**: Session-based generation (24GB)

---

## 7. Integration Architecture for Ardour

### 7.1 Proposed Music AI MCP Server

**Name**: `music-ai-mcp`
**Architecture**: Multi-module Python MCP server

```
music-ai-mcp/
├── generators/
│   ├── yue.py              # YuE integration
│   ├── diffrhythm.py       # DiffRhythm integration
│   ├── audiocraft.py       # MAGNeT/JASCO/MusicGen
│   └── midi_gen.py         # MIDI transformer integration
├── transcription/
│   ├── basic_pitch.py      # Audio-to-MIDI
│   └── demucs.py           # Source separation
├── rendering/
│   ├── fluidsynth.py       # MIDI-to-audio
│   └── plugin_chain.py     # VST/LV2 processing
├── ardour/
│   └── integration.py      # Ardour import/control
└── server.py               # MCP server entry point
```

### 7.2 MCP Tools Specification

#### 1. `generate_full_song`
```python
{
  "name": "generate_full_song",
  "description": "Generate full-length song with vocals and accompaniment",
  "parameters": {
    "prompt": "trap beat with 808 bass and melodic vocals",
    "duration": 180,  # seconds
    "model": "diffrhythm",  # or "yue"
    "style": "hip-hop"
  },
  "returns": {
    "audio_path": "/path/to/song.wav",
    "metadata": {"bpm": 140, "key": "Cm", "duration": 180}
  }
}
```

#### 2. `generate_conditioned_music`
```python
{
  "name": "generate_conditioned_music",
  "description": "Generate music from chords, drums, and melody (JASCO)",
  "parameters": {
    "text_prompt": "energetic trap beat",
    "chord_progression": "Cm-Ab-Eb-Bb",
    "drum_pattern": "trap",
    "melody_reference": "/path/to/melody.mid",
    "bpm": 140
  },
  "returns": {
    "audio_path": "/path/to/music.wav"
  }
}
```

#### 3. `transcribe_to_midi`
```python
{
  "name": "transcribe_to_midi",
  "description": "Convert audio to MIDI using Basic Pitch",
  "parameters": {
    "audio_path": "/path/to/audio.wav",
    "include_pitch_bend": true,
    "onset_threshold": 0.5
  },
  "returns": {
    "midi_path": "/path/to/output.mid",
    "note_events": []
  }
}
```

#### 4. `separate_stems`
```python
{
  "name": "separate_stems",
  "description": "Separate audio into stems using Demucs",
  "parameters": {
    "audio_path": "/path/to/mix.wav",
    "model": "htdemucs_ft",
    "stems": ["drums", "bass", "vocals", "other"]
  },
  "returns": {
    "stems": {
      "drums": "/path/to/drums.wav",
      "bass": "/path/to/bass.wav",
      "vocals": "/path/to/vocals.wav",
      "other": "/path/to/other.wav"
    }
  }
}
```

#### 5. `render_midi_with_plugin`
```python
{
  "name": "render_midi_with_plugin",
  "description": "Render MIDI using VST/LV2 plugin via Carla",
  "parameters": {
    "midi_path": "/path/to/sequence.mid",
    "plugin": "Helm",  # or "Surge XT", "808XD"
    "preset": "808 Bass Heavy",
    "output_format": "wav"
  },
  "returns": {
    "audio_path": "/path/to/rendered.wav"
  }
}
```

#### 6. `import_to_ardour`
```python
{
  "name": "import_to_ardour",
  "description": "Import audio/MIDI files to Ardour session",
  "parameters": {
    "session_path": "/path/to/session.ardour",
    "files": [
      {"path": "/path/to/drums.wav", "track": "Drums", "position": 0},
      {"path": "/path/to/bass.wav", "track": "Bass", "position": 0}
    ],
    "auto_create_tracks": true
  },
  "returns": {
    "success": true,
    "tracks_created": ["Drums", "Bass"]
  }
}
```

---

## 8. Practical Workflows

### 8.1 Hip-Hop Beat Creation (Full Stack)

```
User Prompt: "Create a trap beat with 808 bass, hi-hats, and melodic keys at 140 BPM"

Step 1: Generate full beat with DiffRhythm
  → diffrhythm.generate(prompt="trap beat 808 bass hi-hats melodic 140 BPM", duration=120)
  → Output: beat.wav

Step 2: Separate stems with Demucs
  → demucs.separate(beat.wav, stems=["drums", "bass", "other"])
  → Output: drums.wav, bass.wav, melody.wav

Step 3: Transcribe bass to MIDI for editing
  → basic_pitch.transcribe(bass.wav)
  → Output: bass.mid

Step 4: Re-render bass with custom 808 plugin
  → carla.render_midi(bass.mid, plugin="808XD", preset="Heavy Trap")
  → Output: bass_custom.wav

Step 5: Import to Ardour
  → ardour.import([
      {file: drums.wav, track: "Drums", position: 0},
      {file: bass_custom.wav, track: "808 Bass", position: 0},
      {file: melody.wav, track: "Keys", position: 0}
    ])

Result: Multi-track project ready for vocal recording and mixing
```

---

### 8.2 Sample-Based Production (EDM)

```
User Prompt: "Create a house track at 125 BPM with classic 909 drums"

Step 1: Load open source TR-909 dataset
  → Load EDM-TR9 dataset (3780 loops)
  → Filter: 125 BPM, house style

Step 2: Generate MIDI drum pattern with transformer
  → midi_transformer.generate(prompt="house 909 pattern 125 BPM", bars=16)
  → Output: drums.mid

Step 3: Generate bassline with JASCO
  → audiocraft_jasco.generate(
      text="deep house bassline",
      midi_conditioning=drums.mid,
      chord_progression="Am-Dm-G-C",
      duration=32
    )
  → Output: bass.wav

Step 4: Import 909 samples to Hydrogen
  → hydrogen.import_samples(tr909_dataset)
  → hydrogen.load_midi(drums.mid)
  → Export: drums.wav

Step 5: Arrange in Ardour
  → ardour.import([
      {file: drums.wav, track: "909 Drums", position: 0},
      {file: bass.wav, track: "House Bass", position: 0}
    ])

Step 6: Add effects via Carla + LSP plugins
  → carla.load_chain([
      {plugin: "LSP Compressor", track: "909 Drums"},
      {plugin: "LSP EQ", track: "House Bass"}
    ])
```

---

### 8.3 Full Song Generation (YuE)

```
User Prompt: "Create a 3-minute hip-hop song with vocals about overcoming obstacles"

Step 1: Generate lyrics (external LLM)
  → claude.generate_lyrics(theme="overcoming obstacles", genre="hip-hop")
  → Output: lyrics.txt

Step 2: Generate full song with YuE
  → yue.generate(
      lyrics=lyrics.txt,
      style="hip-hop",
      duration=180,
      session_mode=true  # For 24GB VRAM
    )
  → Output: song_verse.wav, song_chorus.wav (2 sessions)

Step 3: Arrange sessions in Ardour
  → ardour.import([
      {file: song_verse.wav, track: "Verse 1", position: 0},
      {file: song_chorus.wav, track: "Chorus", position: 32}
    ])

Step 4: Separate vocals from accompaniment
  → demucs.separate(song_verse.wav, stems=["vocals", "accompaniment"])
  → demucs.separate(song_chorus.wav, stems=["vocals", "accompaniment"])

Step 5: Fine-tune vocal track
  → ardour.apply_effects(track="Vocals", effects=["EQ", "Compression", "Reverb"])

Result: Professional-quality song structure ready for final mixing
```

---

### 8.4 Style Transfer & Remixing

```
User Prompt: "Take this pop song and make it a trap remix"

Step 1: Separate original song stems
  → demucs.separate(original.wav, model="htdemucs_6s")
  → Output: vocals.wav, bass.wav, drums.wav, guitar.wav, piano.wav, other.wav

Step 2: Transcribe vocal melody to MIDI
  → basic_pitch.transcribe(vocals.wav)
  → Output: vocal_melody.mid

Step 3: Generate trap beat with melody conditioning (JASCO)
  → audiocraft_jasco.generate(
      text="hard trap beat 140 BPM",
      melody_reference=vocal_melody.mid,
      drum_pattern="trap"
    )
  → Output: trap_beat.wav

Step 4: Generate 808 bass matching original bassline
  → basic_pitch.transcribe(bass.wav)
  → Output: bass.mid
  → carla.render_midi(bass.mid, plugin="808XD")
  → Output: 808_bass.wav

Step 5: Time-stretch vocals to 140 BPM
  → ardour.import_with_timestretch(vocals.wav, from_bpm=120, to_bpm=140)

Step 6: Assemble remix
  → ardour.import([
      {file: trap_beat.wav, track: "Trap Drums", position: 0},
      {file: 808_bass.wav, track: "808 Bass", position: 0},
      {file: vocals_stretched.wav, track: "Vocals", position: 0}
    ])

Result: Complete trap remix with original vocals
```

---

## 9. Installation Guide for DGX Spark

### 9.1 System Preparation

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install build essentials
sudo apt-get install -y build-essential git cmake pkg-config

# Install audio libraries
sudo apt-get install -y \
  libasound2-dev \
  libjack-jackd2-dev \
  libsndfile1-dev \
  libfftw3-dev \
  libsamplerate0-dev

# Install Python development
sudo apt-get install -y python3-dev python3-pip python3-venv
```

---

### 9.2 Music AI Tools Installation

#### Core Python Environment
```bash
# Create virtual environment
python3 -m venv ~/music-ai-env
source ~/music-ai-env/bin/activate

# Install PyTorch with CUDA support (verify DGX Spark CUDA version first)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install audio processing libraries
pip install \
  librosa \
  soundfile \
  pydub \
  pretty_midi \
  midiutil \
  music21
```

#### DiffRhythm Installation
```bash
git clone https://github.com/ASLP-lab/DiffRhythm.git
cd DiffRhythm
pip install -r requirements.txt
sudo apt-get install espeak-ng

# Test installation
python infer.py --prompt "trap beat 140 BPM" --duration 60 --chunked
```

#### AudioCraft Installation
```bash
pip install -U audiocraft

# Test MusicGen
python -c "
from audiocraft.models import MusicGen
model = MusicGen.get_pretrained('small')
print('AudioCraft installed successfully')
"
```

#### Basic Pitch Installation
```bash
pip install basic-pitch

# Test installation
basic-pitch --help
```

#### Demucs Installation
```bash
pip install -U demucs

# Test installation
demucs --help
```

#### YuE Installation (Session Mode for 24GB)
```bash
git clone https://github.com/multimodal-art-projection/YuE.git
cd YuE
pip install -r requirements.txt

# Install Flash Attention 2 (critical for memory efficiency)
pip install flash-attn --no-build-isolation

# Test installation
python infer.py --help
```

---

### 9.3 DAW & Plugin Installation

#### Ardour Installation
```bash
# From Ubuntu repositories
sudo apt-get install ardour

# Or download latest from ardour.org
wget https://ardour.org/download.html
# Follow installation instructions
```

#### Carla Plugin Host
```bash
sudo apt-get install carla carla-lv2 carla-vst

# Test installation
carla
```

#### FluidSynth & SoundFonts
```bash
sudo apt-get install fluidsynth fluid-soundfont-gm fluid-soundfont-gs qsynth

# Install additional SoundFonts
mkdir -p ~/soundfonts
cd ~/soundfonts
wget https://musical-artifacts.com/artifacts/1/FluidR3_GM.sf2

# Test FluidSynth
fluidsynth --version
```

#### Free Synth Plugins
```bash
# Surge XT
sudo add-apt-repository ppa:surge-synth-team/surge-synth-team
sudo apt-get update
sudo apt-get install surge-xt-linux

# Helm
wget https://github.com/mtytel/helm/releases/download/v0.9.0/helm-0.9.0-linux.tar.gz
tar -xzf helm-0.9.0-linux.tar.gz
# Copy .so files to /usr/lib/lv2/ or ~/.lv2/

# ZynAddSubFX
sudo apt-get install zynaddsubfx zynaddsubfx-dssi zynaddsubfx-lv2
```

#### Hydrogen Drum Machine
```bash
sudo apt-get install hydrogen
```

---

### 9.4 MIDI Transformer Installation

```bash
# SkyTNT midi-model
git clone https://github.com/SkyTNT/midi-model.git
cd midi-model
pip install -r requirements.txt

# Test model
python generate.py --prompt "piano melody" --output test.mid
```

---

### 9.5 Verification Tests

#### Test 1: MIDI Rendering
```bash
# Create test MIDI file
python -c "
from midiutil import MIDIFile
midi = MIDIFile(1)
midi.addTempo(0, 0, 120)
midi.addNote(0, 0, 60, 0, 1, 100)
with open('test.mid', 'wb') as f:
    midi.writeFile(f)
"

# Render with FluidSynth
fluidsynth -ni -g 1.0 -r 48000 -F test.wav \
  /usr/share/sounds/sf2/FluidR3_GM.sf2 test.mid

# Verify output
file test.wav
```

#### Test 2: Audio Generation (AudioCraft)
```bash
python -c "
from audiocraft.models import MusicGen
model = MusicGen.get_pretrained('small')
model.set_generation_params(duration=8)
wav = model.generate(['trap beat 140 BPM'])
print('Audio generation successful')
"
```

#### Test 3: Audio-to-MIDI Transcription
```bash
# Generate test audio
python -c "
import numpy as np
import soundfile as sf
sr = 22050
t = np.linspace(0, 1, sr)
audio = np.sin(2 * np.pi * 440 * t)  # A4 note
sf.write('test_audio.wav', audio, sr)
"

# Transcribe
basic-pitch output/ test_audio.wav

# Verify MIDI output
ls output/*.mid
```

#### Test 4: Source Separation
```bash
# Download test audio
wget https://freesound.org/people/example/sounds/test.wav -O test_mix.wav

# Separate stems
demucs test_mix.wav

# Verify output
ls separated/htdemucs/test_mix/
```

#### Test 5: Carla Plugin Loading
```bash
# Launch Carla (GUI)
carla &

# Load a plugin and verify it appears
# Test: File > Add Plugin > Search for "Surge" or "Helm"
```

---

## 10. Performance Benchmarks (Estimated)

### DGX Spark Performance Projections

| Task | Model | Duration | Est. Time | VRAM Usage |
|------|-------|----------|-----------|------------|
| Full song generation | DiffRhythm (4m45s) | 285s | ~10s | 8-12GB |
| Full song generation | YuE (session mode) | 30s | 150-360s | 24GB |
| Audio generation | AudioCraft MAGNeT | 10s | 4s | 8GB |
| MIDI transcription | Basic Pitch | 60s | <1s | CPU-only |
| Source separation | Demucs htdemucs_ft | 60s | 90s | 7GB |
| MIDI rendering | FluidSynth | 60s | <1s | CPU-only |
| MIDI generation | SkyTNT midi-model | 32 bars | 2-5s | 4GB |

**Note**: Times are estimates based on reported benchmarks. Actual performance on DGX Spark will vary.

---

## 11. Limitations & Challenges

### 11.1 Hardware Constraints

**VRAM Limitations**:
- DGX Spark GPU VRAM unknown (assumed <80GB)
- YuE full song mode requires 80GB (use session mode)
- Consider cloud hybrid for large model inference

**ARM Compatibility**:
- Most PyTorch models compatible
- Some CUDA-specific code may need adaptation
- Test thoroughly before production use

---

### 11.2 Model Quality Variations

**Consistency Issues**:
- AI-generated music quality varies per generation
- Genre-specific training affects output quality
- May require multiple generations to get desired result

**Mitigation**:
- Generate multiple variations
- Use as starting point for manual editing
- Combine multiple models (e.g., JASCO + manual mixing)

---

### 11.3 Licensing Considerations

| Tool | License | Commercial Use |
|------|---------|----------------|
| YuE | Apache 2.0 | Yes (with attribution) |
| DiffRhythm | Apache 2.0 | Yes |
| AudioCraft | CC-BY-NC 4.0 | No (research only) |
| Stable Audio Open | Non-commercial | No |
| Basic Pitch | Open source | Yes |
| Demucs | MIT | Yes |

**Recommendation**: For commercial projects, prioritize YuE and DiffRhythm.

---

### 11.4 Real-Time Performance

**Not Suitable for Live Performance**:
- Most models require seconds to minutes for generation
- NeuralNote VST: Fast transcription but not real-time instrument playing

**Use Cases**:
- Studio production: Excellent
- Live performance: Limited (pre-render required)

---

## 12. Future Developments to Watch

### 12.1 Emerging Models (Expected 2025+)

1. **AudioCraft Next Gen**: Meta's next iteration (rumored)
2. **Stable Audio 3.0**: Improved length and quality
3. **YuE v2**: Community fine-tunes and extensions
4. **Open-Source Suno Alternatives**: Multiple projects in development

---

### 12.2 Hardware Trends

1. **ARM AI Accelerators**: Specialized music generation chips
2. **Neural Processing Units**: On-device inference (smartphones, tablets)
3. **Distributed Generation**: Multi-device collaboration

---

### 12.3 Integration Improvements

1. **Native DAW Plugins**: AI generation as VST/LV2 plugins
2. **Real-Time Assistance**: AI co-pilot for music production
3. **Cross-Platform Standards**: Unified APIs for music AI tools

---

## 13. Recommended Priority Stack for DGX Spark

### Tier 1: Immediate Deployment (CPU-based, stable)
1. **FluidSynth** - MIDI rendering
2. **Basic Pitch** - Audio-to-MIDI
3. **Ardour** - DAW
4. **Carla** - Plugin hosting
5. **Free VST plugins** (Helm, Surge XT, 808XD)

### Tier 2: GPU Tools (Test on DGX Spark)
1. **Stable Audio Open Small** - ARM-optimized, test first
2. **DiffRhythm** - 8GB VRAM, full song generation
3. **AudioCraft MAGNeT** - Fast text-to-music

### Tier 3: Advanced Features (Requires validation)
1. **Demucs v4** - Source separation (7GB VRAM)
2. **MIDI Transformers** - Symbolic generation
3. **YuE (session mode)** - Full songs with 24GB VRAM

### Tier 4: Cloud Hybrid (For heavy workloads)
1. **YuE (full mode)** - 80GB VRAM required
2. **Large model fine-tuning**
3. **Batch generation jobs**

---

## 14. Next Steps & Action Plan

### Phase 1: Foundation (Week 1-2)
- [ ] Install Ardour + Carla + FluidSynth
- [ ] Test MIDI rendering pipeline
- [ ] Install free VST plugins (Helm, Surge XT, 808XD)
- [ ] Verify plugin loading in Carla
- [ ] Test Basic Pitch audio-to-MIDI transcription

### Phase 2: GPU Tools (Week 3-4)
- [ ] Verify CUDA on DGX Spark
- [ ] Install PyTorch with CUDA support
- [ ] Test Stable Audio Open Small (ARM-optimized)
- [ ] Install and test DiffRhythm
- [ ] Benchmark performance (time, VRAM usage)

### Phase 3: Integration (Week 5-6)
- [ ] Build music-ai-mcp server prototype
- [ ] Implement core tools (generate, transcribe, render)
- [ ] Test Ardour integration workflows
- [ ] Document successful workflows

### Phase 4: Production (Week 7-8)
- [ ] Fine-tune generation prompts
- [ ] Create preset workflows (hip-hop, EDM, etc.)
- [ ] Build user documentation
- [ ] Optimize for DGX Spark performance

### Phase 5: Advanced Features (Week 9-12)
- [ ] Implement JASCO chord conditioning
- [ ] Test YuE session-based generation
- [ ] Add Demucs stem separation
- [ ] Build complete production workflows

---

## 15. Resources & Links

### Official Repositories
- **YuE**: https://github.com/multimodal-art-projection/YuE
- **DiffRhythm**: https://github.com/ASLP-lab/DiffRhythm
- **AudioCraft**: https://github.com/facebookresearch/audiocraft
- **Basic Pitch**: https://github.com/spotify/basic-pitch
- **Demucs**: https://github.com/facebookresearch/demucs
- **Carla**: https://github.com/falkTX/Carla
- **NeuralNote**: https://github.com/DamRsn/NeuralNote

### Demos & Web Tools
- **Basic Pitch Demo**: https://basicpitch.spotify.com
- **DiffRhythm Demo**: https://diffrhythm.com
- **iO-808**: https://io808.com
- **Stable Audio**: https://stability.ai/stable-audio

### HuggingFace Models
- **YuE Models**: https://huggingface.co/multimodal-art-projection
- **DiffRhythm Models**: https://huggingface.co/ASLP-lab/DiffRhythm
- **AudioCraft Models**: https://huggingface.co/facebook
- **SkyTNT MIDI Model**: https://huggingface.co/skytnt/midi-model

### Sample Libraries
- **EDM TR-909 Dataset**: CC BY 4.0 (3780 loops)
- **EDM TR-808 Dataset**: CC BY 4.0 (3790 loops)
- **99sounds**: https://99sounds.org (free sample packs)
- **Freesound**: https://freesound.org (CC-licensed sounds)
- **Musical Artifacts**: https://musical-artifacts.com (SoundFonts, samples)

### Documentation
- **Ardour Manual**: https://manual.ardour.org
- **FluidSynth Documentation**: https://www.fluidsynth.org
- **PyTorch Audio**: https://pytorch.org/audio/stable/index.html
- **LV2 Plugin Specification**: https://lv2plug.in

### Research Papers
- **YuE**: "Open Full-song Music Generation Foundation Model"
- **DiffRhythm**: "Blazingly Fast End-to-End Full-Length Song Generation"
- **JASCO**: "Joint Audio and Symbolic Conditioning" (arXiv:2406.10970)
- **MAGNeT**: "Masked Audio Generation using a Single Non-Autoregressive Transformer"
- **Text2MIDI**: AAAI 2025 Conference Paper
- **Basic Pitch**: "A Lightweight Instrument-Agnostic Model" (ICASSP 2022)

---

## 16. Conclusion

The open source music AI ecosystem has reached production maturity in 2024-2025 with:

1. **Full song generation** (YuE, DiffRhythm) under permissive licenses
2. **Advanced conditioning** (JASCO) for precise control
3. **ARM-optimized models** (Stable Audio Open Small) for edge devices
4. **Mature transcription** (Basic Pitch, Demucs) for audio analysis
5. **Comprehensive tooling** (Carla, Ardour, FluidSynth) for DAW integration

**DGX Spark is well-positioned** for music AI deployment with:
- ARM64 architecture support from Stable Audio Open Small
- 128GB unified memory for model loading
- Integrated NVIDIA GPU for CUDA-accelerated inference
- Linux-native environment for open source tools

**Recommended Strategy**:
1. Start with CPU-based tools (FluidSynth, Basic Pitch, Ardour)
2. Test GPU tools (Stable Audio Small, DiffRhythm)
3. Build unified MCP server for seamless workflow
4. Use cloud hybrid for heavy workloads (YuE full mode)

**The vision of natural language music production integrated with professional DAWs is now achievable with fully open source tools.**

---

**Document Status**: Research Complete - Ready for Implementation
**Last Updated**: November 6, 2025
**Next Action**: Begin Phase 1 foundation setup on DGX Spark
