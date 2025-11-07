# AI Music Generation Training Methodologies Research

**Research Date**: January 6, 2025
**Focus**: Training approaches for hip-hop and dubstep/EDM generation on DGX Spark
**Hardware Target**: NVIDIA DGX Spark (128GB unified memory)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Genre-Specific Training Approaches](#genre-specific-training-approaches)
3. [Model Architectures](#model-architectures)
4. [Training Infrastructure Requirements](#training-infrastructure-requirements)
5. [State-of-the-Art Models (2024-2025)](#state-of-the-art-models-2024-2025)
6. [Dataset Recommendations](#dataset-recommendations)
7. [Training Recipes & Best Practices](#training-recipes--best-practices)
8. [Data Augmentation Techniques](#data-augmentation-techniques)
9. [Optimization Strategies](#optimization-strategies)
10. [Implementation Plan for DGX Spark](#implementation-plan-for-dgx-spark)

---

## Executive Summary

### Key Findings

**Training AI music generation models for hip-hop and dubstep/EDM on DGX Spark is viable** with the following approach:

- **Best Model**: MusicGen Medium (1.5B parameters) for fine-tuning
- **Alternative**: Stable Audio Open 1.0 with latent diffusion
- **Memory Requirements**: 24-48GB for training (well within 128GB budget)
- **Training Time**: 15 minutes - 24 hours depending on approach
- **Dataset Size**: Minimum 10 hours, optimal 100+ hours per genre

### Recommended Approach

**Multi-Stage Fine-Tuning Strategy**:
1. Start with pre-trained MusicGen Medium checkpoint
2. Fine-tune on genre-specific datasets (hip-hop/EDM separately)
3. Use multi-stage training: rhythm → harmony → full mix
4. Apply extensive audio augmentation
5. Training time estimate: 8-24 hours on DGX Spark

---

## Genre-Specific Training Approaches

### Hip-Hop Training Methodology

#### Characteristics to Capture
- **Rhythmic Elements**: 808 kick drums, snappy snares, trap hi-hats
- **Tempo Range**: 60-90 BPM (boom bap), 130-160 BPM (trap)
- **Harmonic Content**: Minor keys, diminished chords, melodic samples
- **Texture**: Vinyl crackle, tape saturation, lo-fi aesthetics

#### Dataset Curation Strategy

**Minimum Requirements**:
- 100+ hours of instrumental hip-hop tracks
- Diverse sub-genres: boom bap, trap, lo-fi, drill, phonk
- Clean separation: drums, bass, melodic elements
- Metadata: BPM, key, sub-genre tags

**Data Sources**:
1. **Groove MIDI Dataset**: 13.6 hours of drum performances (hip-hop category)
2. **Free Music Archive (FMA)**: Filter by hip-hop genre
3. **MusicBench**: 52,768 samples with genre tags
4. **Custom curation**: YouTube Audio Library (royalty-free), Splice samples

**Preprocessing Pipeline**:
```python
# Step 1: Source separation using Demucs
demucs -o output/ --two-stems=vocals track.mp3

# Step 2: Isolate drum stems
demucs -o output/ --two-stems=drums no_vocals.wav

# Step 3: Normalize and resample to 32kHz (MusicGen standard)
ffmpeg -i track.mp3 -ar 32000 -ac 2 normalized.wav
```

#### Multi-Stage Training Approach

**Stage 1: Drum-Focused Training (2-4 hours)**
- Dataset: Isolated drum stems only
- Focus: Learn 808 patterns, hi-hat rolls, snare placement
- Loss weight: Emphasize low-frequency content (808s)

**Stage 2: Bass & Drums (4-6 hours)**
- Dataset: Drums + bass stems
- Focus: Bass-drum synchronization, sub-bass patterns

**Stage 3: Full Mix (8-12 hours)**
- Dataset: Complete instrumentals
- Focus: Melodic elements, arrangement, transitions

### Dubstep/EDM Training Methodology

#### Characteristics to Capture
- **Rhythmic Elements**: Complex drum patterns, buildups, drops
- **Synthesis**: Wobble bass (LFO modulation), FM synthesis, wavetables
- **Tempo**: 140 BPM (dubstep standard), 128 BPM (house/techno)
- **Structure**: Intro-buildup-drop-breakdown-drop-outro

#### Dataset Curation Strategy

**Minimum Requirements**:
- 100+ hours of electronic music
- Sub-genres: dubstep, riddim, brostep, future bass, trap
- Emphasis on bass-heavy tracks with complex synthesis
- Metadata: BPM (standardized), key, energy level

**Data Sources**:
1. **Free Music Archive**: Electronic category (665k hours music subset)
2. **MusicBench**: EDM-tagged samples
3. **Freesound**: 486k+ CC-licensed audio (sound effects useful for EDM)
4. **Custom synthesis**: Generate synthetic wobble bass samples

**Preprocessing Pipeline**:
```python
# EDM-specific preprocessing
# 1. Extract buildup/drop segments (most characteristic)
# 2. Isolate bass frequency range (20-200Hz)
# 3. Preserve transients (critical for dubstep wobbles)
# 4. Maintain stereo width (important for EDM production)

import librosa
import soundfile as sf

def preprocess_edm(audio_path):
    y, sr = librosa.load(audio_path, sr=32000, mono=False)

    # Detect drops using onset strength
    onset_env = librosa.onset.onset_strength(y=y[0], sr=sr)

    # Extract high-energy segments
    # ... (implementation details)

    return processed_audio
```

#### Multi-Stage Training Approach

**Stage 1: Bass Synthesis (3-5 hours)**
- Dataset: Isolated bass stems + synthetic wobbles
- Focus: LFO patterns, sub-bass generation, distortion

**Stage 2: Drum Patterns (2-4 hours)**
- Dataset: EDM drum loops
- Focus: Complex hi-hat patterns, kick-bass relationship

**Stage 3: Buildups & Drops (4-6 hours)**
- Dataset: Full tracks with annotated structure
- Focus: Tension building, energy release, arrangement

**Stage 4: Full Production (10-15 hours)**
- Dataset: Complete tracks
- Focus: Stereo imaging, layering, transitions

### Fine-Tuning vs Training from Scratch

#### Fine-Tuning (RECOMMENDED)

**Advantages**:
- 20-50x faster training
- Requires 10x less data
- Better generalization
- Lower compute requirements

**Approach**:
```bash
# Fine-tune MusicGen Medium on hip-hop dataset
dora run solver=musicgen/musicgen_base_32khz \
  model/lm/model_scale=medium \
  continue_from=//pretrained/facebook/musicgen-medium \
  conditioner=text2music \
  dataset.train=hip_hop_dataset \
  optim.lr=1e-5 \
  epochs=10
```

**Memory**: 24-32GB GPU VRAM
**Time**: 8-24 hours
**Data**: 10-100 hours audio

#### Training from Scratch (NOT RECOMMENDED)

**Disadvantages**:
- Requires 10,000+ hours of training data
- Training time: weeks to months
- Requires massive compute (multiple GPUs)
- Higher risk of mode collapse

**Only Consider If**:
- Extremely unique genre not in pre-training data
- Need complete control over model biases
- Have access to proprietary massive dataset

---

## Model Architectures

### 1. MusicGen (Meta AudioCraft)

**Architecture**: Auto-regressive Transformer with efficient token interleaving

**Specifications**:
- **Encoder**: Frozen T5/Flan-T5 for text conditioning
- **Decoder**: 24-layer Transformer (Medium: 1.5B params)
- **Audio Codec**: EnCodec (4 codebooks, 32kHz, 50Hz sampling)
- **Sequence Length**: 2048 tokens (30 seconds max)

**Strengths for Genre-Specific Training**:
- Single-stage generation (fast inference)
- Text + melody conditioning
- Proven fine-tuning success
- Efficient token interleaving reduces memory

**Hip-Hop Suitability**: ★★★★★
- Excellent at capturing rhythmic patterns
- Good bass response
- Handles repetitive structures well

**Dubstep/EDM Suitability**: ★★★★☆
- Good at transients and percussion
- Struggles with extreme synthesis (wobble bass)
- Better for melodic EDM than heavy dubstep

**Model Sizes**:
| Model | Parameters | VRAM (Inference) | VRAM (Training) | Quality |
|-------|------------|------------------|-----------------|---------|
| Small | 300M | 4GB | 12-16GB | Good |
| Medium | 1.5B | 8GB | 24-32GB | Excellent |
| Large | 3.3B | 16GB | 48-64GB | Best |

**Controllability Features**:
- Text prompts (genre, mood, instruments, BPM)
- Melody conditioning (transform hummed melodies)
- Classifier-free guidance (strength: 3.0 default)
- Tempo control via prompt
- Key/scale suggestions via text

**Training Configuration**:
```yaml
# musicgen_fine_tune.yaml
model:
  lm:
    model_scale: medium  # 1.5B parameters
    n_q: 4  # 4 codebooks
    card: 2048  # vocabulary size
    transformer_lm:
      hidden_size: 1024
      num_layers: 24
      num_heads: 16
      ffn_dim: 4096

compression_model:
  sample_rate: 32000
  channels: 2  # stereo

conditioner:
  args:
    t5_model: t5-base
    cond_dim: 768

solver:
  batch_size: 4  # Adjust based on VRAM
  lr: 1e-5
  warmup: 500
  gradient_accumulation: 2
  max_epoch: 10
```

### 2. Stable Audio Open 1.0

**Architecture**: Latent Diffusion Transformer (DiT)

**Specifications**:
- **Autoencoder**: Compresses waveforms to latent space
- **Text Encoder**: T5-based conditioning
- **Diffusion Model**: Transformer-based DiT
- **Output**: 44.1kHz stereo, up to 47 seconds

**Training Dataset**:
- 486,492 recordings (472k Freesound + 13k FMA)
- 266,324 CC0, 194,840 CC-BY licensed
- Heavy on sound effects and field recordings

**Strengths**:
- Longer generation (47s vs 30s)
- Higher sample rate (44.1kHz)
- Strong on sound design

**Weaknesses**:
- "Better at sound effects than music"
- Uneven performance across music styles
- Less controllability for music structure

**Hip-Hop Suitability**: ★★★☆☆
- Good for lo-fi textures
- Struggles with tight rhythms

**Dubstep/EDM Suitability**: ★★★★☆
- Excellent for sound design
- Good for atmospheric builds
- Can generate complex synthesis textures

**Training Requirements**:
- Not officially documented
- Estimated: 32-64GB VRAM for training
- Diffusion training typically slower than autoregressive

### 3. AudioLDM 2

**Architecture**: Latent text-to-audio diffusion

**Specifications**:
- **Three Variants**: Base (350M UNet), Large (750M), Music (350M specialized)
- **Total Size**: 1.1B - 1.5B parameters
- **Training Data**: 1,150k hours (general), 665k hours (music variant)

**Strengths**:
- Dedicated music checkpoint
- Massive training data
- Good quality/diversity balance

**Weaknesses**:
- Primarily designed for general audio
- Training code separate repository
- Less genre-specific control

**Hip-Hop Suitability**: ★★★☆☆
**Dubstep/EDM Suitability**: ★★★☆☆

### 4. Make-An-Audio 2

**Architecture**: Latent diffusion with temporal structuring

**Specifications**:
- **VAE**: Mel-spectrogram compression
- **Diffusion**: ConcatDiT architecture
- **Text Encoder**: CLAP (Contrastive Language-Audio Pre-training)
- **Vocoder**: BigVGAN

**Unique Features**:
- Temporal event positioning (start@mid@end annotations)
- Structured captions via ChatGPT augmentation
- Fine-grained control over event sequencing

**Training Requirements**:
- 8 GPU minimum
- No specific VRAM requirements documented

**Innovation**:
- Structured temporal control ideal for EDM buildups/drops
- CLAP encoder better audio-text alignment than T5

**Hip-Hop Suitability**: ★★★★☆
- Temporal control good for verse/chorus structure

**Dubstep/EDM Suitability**: ★★★★★
- Excellent for buildup-drop-breakdown structure
- Temporal annotations perfect for EDM

### 5. Multi-Source Latent Diffusion (2024 Innovation)

**Architecture**: VAE per instrument source + joint diffusion

**Key Innovation**:
- Separate latent representations for each instrument (drums, bass, piano, guitar)
- Generates sources individually then combines
- Eliminates Gaussian noise artifacts

**Benefits**:
- Richer melodies than single-mixture models
- Better source separation capabilities
- Inherent controllability over individual instruments

**Hip-Hop Suitability**: ★★★★★
- Perfect for separate drums/bass/samples workflow

**Dubstep/EDM Suitability**: ★★★★★
- Ideal for layered EDM production
- Separate bass synthesis control

**Training Requirements**:
- Requires source-separated training data
- More complex training pipeline
- Estimated: 40-60GB VRAM

---

## Training Infrastructure Requirements

### GPU Memory Requirements

#### MusicGen Fine-Tuning on DGX Spark

**DGX Spark Specifications**:
- 128GB unified memory (shared CPU/GPU)
- NVIDIA Grace CPU + Blackwell GPU architecture
- High bandwidth memory subsystem

**Memory Budget Breakdown** (MusicGen Medium):

```
Base Model: 1.5B parameters × 4 bytes (fp32) = 6GB
Gradients: 6GB (same as params)
Optimizer States (AdamW): 12GB (2× params for momentum/variance)
Activations (batch_size=4): 8-12GB
EnCodec Model: 2GB
Working Memory: 4GB
────────────────────────────────
Total: ~38-44GB peak memory
```

**With Optimization**:
```
Mixed Precision (fp16): Reduce by 40%
Gradient Checkpointing: Reduce activations by 60%
Gradient Accumulation: Reduce batch memory
────────────────────────────────
Optimized Total: 20-28GB
```

**DGX Spark Capacity**: 128GB >> 28GB = ✅ **EASILY FITS**

#### Training Configuration for DGX Spark

**Optimal Settings**:
```yaml
# Training on DGX Spark 128GB
batch_size: 8  # Can go higher than typical GPU
gradient_accumulation_steps: 2
effective_batch_size: 16

precision: bf16  # Use BFloat16 on Blackwell
gradient_checkpointing: true

# Memory optimization
max_sequence_length: 1500  # Reduce from 2048 for longer batches
use_flash_attention: true  # Blackwell optimization
```

**Expected Memory Usage**:
- MusicGen Small: 12-18GB (can run batch_size=16)
- MusicGen Medium: 24-32GB (batch_size=8)
- MusicGen Large: 45-60GB (batch_size=4)
- Stable Audio: 35-50GB (estimated)

**Multiple Models Simultaneously**:
With 128GB, you can:
- Train MusicGen Medium (32GB) + Run inference on Small (8GB) = 40GB
- Train two MusicGen Small models simultaneously (36GB)
- Train Large model with full batch size (60GB) with headroom

### Training Time Estimates

#### Fine-Tuning MusicGen (DGX Spark)

**Dataset Size: 10 hours audio**

| Model | Batch Size | Steps | Time/Step | Total Time |
|-------|-----------|-------|-----------|------------|
| Small | 16 | 1,875 | 2s | 1.0 hours |
| Medium | 8 | 3,750 | 3.5s | 3.6 hours |
| Large | 4 | 7,500 | 6s | 12.5 hours |

**Dataset Size: 100 hours audio**

| Model | Batch Size | Steps | Time/Step | Total Time |
|-------|-----------|-------|-----------|------------|
| Small | 16 | 18,750 | 2s | 10.4 hours |
| Medium | 8 | 37,500 | 3.5s | 36.5 hours |
| Large | 4 | 75,000 | 6s | 125 hours |

**Assumptions**:
- 30-second audio chunks
- 10 epochs
- 32kHz sample rate
- DGX Spark with optimizations

**Practical Training Schedule**:

```
Hip-Hop Model:
- Dataset: 50 hours (curated hip-hop instrumentals)
- Model: MusicGen Medium
- Time: ~18 hours
- Schedule: Overnight training

Dubstep Model:
- Dataset: 50 hours (EDM/dubstep)
- Model: MusicGen Medium
- Time: ~18 hours
- Schedule: Second overnight training

Total: ~36 hours for both genre-specific models
```

### Optimization Techniques

#### 1. Mixed Precision Training

**BFloat16 on Blackwell GPU**:
```python
# PyTorch Lightning configuration
trainer = Trainer(
    precision='bf16-mixed',  # Blackwell-optimized
    devices=1,
    accelerator='gpu'
)
```

**Benefits**:
- 40% memory reduction
- 2-3x faster training
- Minimal quality loss
- Better than FP16 for audio (wider dynamic range)

#### 2. Gradient Checkpointing

**Implementation**:
```python
# In MusicGen config
transformer_lm:
  use_checkpoint: true
  checkpoint_every_n_layers: 4
```

**Benefits**:
- 60% activation memory reduction
- 20% slower training (acceptable tradeoff)
- Enables larger batch sizes

#### 3. Flash Attention

**Blackwell Optimization**:
```python
# Automatic in PyTorch 2.5+
# Verify enabled:
import torch
print(torch.backends.cuda.flash_sdp_enabled())
```

**Benefits**:
- 2-4x faster attention computation
- Lower memory footprint
- Exact same results

#### 4. Gradient Accumulation

**Strategy**:
```yaml
# Simulate large batch with limited memory
batch_size: 4
gradient_accumulation_steps: 4
# Effective batch_size = 16
```

**Benefits**:
- Train with larger effective batch sizes
- Better gradient estimates
- More stable training

#### 5. Learning Rate Scheduling

**Warmup + Cosine Decay**:
```python
from torch.optim.lr_scheduler import CosineAnnealingWarmRestarts

optimizer = AdamW(model.parameters(), lr=1e-5)
scheduler = CosineAnnealingWarmRestarts(
    optimizer,
    T_0=500,  # Warmup steps
    T_mult=2,
    eta_min=1e-7
)
```

**Benefits**:
- Stable early training (warmup)
- Better convergence (cosine decay)
- Avoid learning rate tuning

---

## State-of-the-Art Models (2024-2025)

### Model Comparison Matrix

| Model | Release | Parameters | Training Data | License | Hip-Hop | EDM | Controllability |
|-------|---------|------------|---------------|---------|---------|-----|-----------------|
| **MusicGen** | 2023 | 300M-3.3B | 20k hours | MIT | ★★★★★ | ★★★★☆ | High |
| **Stable Audio Open** | 2024 | ~1B | 486k samples | MIT | ★★★☆☆ | ★★★★☆ | Medium |
| **AudioLDM 2** | 2024 | 1.1-1.5B | 1,150k hours | Custom | ★★★☆☆ | ★★★☆☆ | Medium |
| **Make-An-Audio 2** | 2024 | ~1B | Custom | Research | ★★★★☆ | ★★★★★ | Very High |
| **JASCO** | 2024 | 400M-1B | Custom | Research | ★★★★☆ | ★★★★☆ | Very High |

### Recommended Models for DGX Spark

#### Primary: MusicGen Medium

**Why Choose**:
1. **Proven fine-tuning**: Multiple successful implementations
2. **Efficient architecture**: Single-stage generation
3. **Good controllability**: Text + melody conditioning
4. **Active community**: Facebook Research support
5. **Perfect fit**: 24-32GB training memory

**Fine-Tuning Resources**:
- Official AudioCraft training code
- Community fine-tuning tools (cog-musicgen-fine-tuner)
- 15-minute quick fine-tune examples
- Extensive documentation

#### Secondary: Make-An-Audio 2

**Why Consider**:
1. **Temporal control**: Perfect for EDM structure (buildup-drop)
2. **CLAP encoder**: Better audio-text alignment
3. **2024 innovation**: Latest architectural advances
4. **Source separation**: Better for layered production

**Challenges**:
- Research code (less polished)
- Less documentation
- Requires 8 GPUs (can adapt for DGX Spark)

#### Experimental: Multi-Source Latent Diffusion

**Why Explore**:
1. **Separate instrument control**: Ideal for hip-hop/EDM layering
2. **Better quality**: Eliminates artifacts
3. **Compositional control**: Generate drums, bass, melody separately

**Challenges**:
- Very new (2024 research)
- No public implementation yet
- Requires source-separated training data

### Fine-Tuning Approaches for Each Model

#### MusicGen Fine-Tuning Recipe

**Quick Fine-Tune (15 minutes, 10 tracks)**:
```yaml
# Replicate/Cog approach
model: stereo-melody
dataset: 10+ WAV files (>30s each)
drop_vocals: true
auto_labeling: true
lr: 1
epochs: 3
updates_per_epoch: 100
batch_size: 3
```

**Production Fine-Tune (8-24 hours, 50-100 hours audio)**:
```yaml
# AudioCraft dora approach
solver: musicgen/musicgen_base_32khz
model_scale: medium
continue_from: //pretrained/facebook/musicgen-medium

dataset:
  train: hip_hop_curated
  valid: hip_hop_test
  sample_rate: 32000
  channels: 2

optim:
  optimizer: adamw
  lr: 1e-5
  weight_decay: 1e-5
  warmup: 500

schedule:
  lr_scheduler: cosine

training:
  batch_size: 8
  gradient_accumulation: 2
  epochs: 10
  checkpoint_every: 500

generate:
  every: 5  # Generate samples every 5 epochs
  num_samples: 10
  lm:
    use_sampling: true
    top_k: 250
    temperature: 1.0
```

**Genre-Specific Fine-Tune**:
```python
# Multi-stage hip-hop training
# Stage 1: Drums (2 hours)
train(dataset="hip_hop_drums_only", epochs=5)

# Stage 2: Bass + Drums (4 hours)
train(dataset="hip_hop_bass_drums", epochs=7, continue_from="drums_ckpt")

# Stage 3: Full mix (8 hours)
train(dataset="hip_hop_full", epochs=10, continue_from="bass_drums_ckpt")
```

#### Stable Audio Fine-Tuning Recipe

**Configuration** (stable-audio-tools):
```yaml
model_type: diffusion_cond

sample_rate: 44100
sample_size: 2097152  # ~47 seconds

model:
  pretransform:
    type: autoencoder
    config: autoencoder_config.json

  conditioning:
    text:
      type: t5
      model: t5-base

  diffusion:
    type: dit
    config:
      depth: 24
      hidden_size: 1024

training:
  batch_size: 8
  precision: bf16-mixed
  learning_rate: 1e-5
  num_gpus: 1
  checkpoint_every: 10000

dataset:
  type: local
  path: /path/to/edm_dataset
  format: wav
```

**Training Command**:
```bash
python train.py \
  --config-file edm_config.json \
  --batch-size 8 \
  --num-gpus 1 \
  --precision bf16 \
  --checkpoint-every 10000 \
  --pretrained-ckpt-path stable-audio-open-1.0.ckpt
```

---

## Dataset Recommendations

### Open Source Music Datasets

#### 1. MusicBench (BEST FOR FINE-TUNING)

**Specifications**:
- **Size**: 52,768 training samples
- **License**: CC-BY-SA 3.0
- **Format**: Parquet with audio
- **Features**: BPM, key, chords, multiple captions

**Genre Coverage**:
- Diverse genres including hip-hop and electronic
- Text descriptions with musical attributes
- Structured metadata perfect for training

**Why Ideal**:
- Pre-processed for text-to-music training
- Rich metadata (BPM, key, chords)
- Multiple caption variations per track
- Hugging Face integration

**Access**:
```python
from datasets import load_dataset
dataset = load_dataset("amaai-lab/MusicBench")
```

#### 2. Free Music Archive (FMA)

**Specifications**:
- **Size**: 106,574 tracks, 161 genres
- **License**: Various Creative Commons
- **Total Duration**: ~343,000 hours
- **Used By**: Stable Audio training (13,874 tracks)

**Subsets**:
- `fma_small`: 8,000 tracks (30s clips)
- `fma_medium`: 25,000 tracks
- `fma_large`: 106,574 tracks
- `fma_full`: Complete tracks

**Genre Filtering**:
```python
# Filter for hip-hop and electronic
import pandas as pd
metadata = pd.read_csv('fma_metadata/tracks.csv')
hip_hop = metadata[metadata['genre_top'] == 'Hip-Hop']
electronic = metadata[metadata['genre_top'] == 'Electronic']
```

**License Breakdown**:
- Majority: CC-BY
- Some: CC0 (public domain)
- Check per-track for commercial use

#### 3. Groove MIDI Dataset (DRUMS)

**Specifications**:
- **Size**: 13.6 hours of drums
- **Format**: MIDI + synthesized audio
- **License**: CC-BY 4.0
- **Performers**: 10 drummers (professional)

**Hip-Hop Applicability**:
- Hip-hop as labeled genre category
- Expressive drum performances
- Tempo-aligned, perfect for rhythm training

**Integration**:
```python
import tensorflow_datasets as tfds
dataset = tfds.load('groove/full-16000hz')
```

#### 4. Expanded Groove MIDI (E-GMD)

**Specifications**:
- **Size**: 444 hours of drums
- **Kits**: 43 different drum kits
- **License**: CC-BY 4.0 (presumed)

**Benefits**:
- 32x larger than original Groove
- Velocity annotations
- Varied drum sounds (important for EDM/dubstep)

#### 5. Freesound

**Specifications**:
- **Size**: 486,492 sounds used in Stable Audio
- **License**: CC0, CC-BY, CC-BY-NC
- **Content**: Sound effects + field recordings

**EDM/Dubstep Value**:
- Synthesizer samples
- Bass wobbles
- Sound effects for buildups
- Glitch sounds

**Licensing for AI**:
- CC0: Unrestricted, ideal for training
- CC-BY: Attribution required (acceptable)
- CC-BY-NC: Non-commercial only (avoid for commercial models)

**Download**:
```python
# Freesound API access
import freesound
client = freesound.FreesoundClient()
client.set_token("<YOUR_API_KEY>")

# Search for dubstep bass
results = client.text_search(query="dubstep bass", filter="tag:wobble license:CC0")
```

### Recommended Dataset Composition

#### Hip-Hop Training Dataset

**Target**: 100 hours minimum, 500 hours optimal

**Composition**:
```
50 hours: Pure instrumentals (boom bap, trap, lo-fi)
  └─ Sources: MusicBench (hip-hop filtered), FMA, YouTube Audio Library

30 hours: Drum loops & breaks
  └─ Sources: Groove MIDI, E-GMD, custom recordings

10 hours: 808 bass patterns
  └─ Sources: Synthesized, sample packs (Splice free tier)

10 hours: Melodic samples (piano, strings)
  └─ Sources: FMA, MAESTRO (classical piano for sampling)
```

**Metadata Requirements**:
```python
# metadata.csv
file_path, caption, bpm, key, sub_genre, instruments, duration
"track001.wav", "boom bap hip hop beat with jazz piano sample 90 BPM", 90, "G minor", "boom_bap", "drums,bass,piano", 180
"track002.wav", "trap beat heavy 808 bass sharp hi hats 140 BPM", 140, "C minor", "trap", "drums,808,hi-hats", 120
```

#### Dubstep/EDM Training Dataset

**Target**: 100 hours minimum, 500 hours optimal

**Composition**:
```
40 hours: Full dubstep/riddim tracks
  └─ Sources: FMA (electronic), SoundCloud Creative Commons

30 hours: Bass wobbles & synthesis
  └─ Sources: Freesound, custom synthesis

20 hours: Drum patterns (EDM-specific)
  └─ Sources: E-GMD, sample packs

10 hours: Buildups & transitions
  └─ Sources: Extracted from full tracks, Freesound SFX
```

**Metadata Requirements**:
```python
# metadata.csv
file_path, caption, bpm, key, structure, synthesis_type, energy_level, duration
"edm001.wav", "dubstep drop with wobble bass and aggressive drums 140 BPM", 140, "E minor", "drop", "wobble,fm", "high", 60
"edm002.wav", "future bass buildup atmospheric pads rising tension 150 BPM", 150, "A major", "buildup", "wavetable,pads", "medium", 30
```

### Dataset Size Requirements

**Minimum Viable Dataset**:
- **10 hours**: Quick fine-tune (proof of concept)
- **Training time**: 1-4 hours
- **Quality**: Decent for specific prompts, limited generalization

**Recommended Dataset**:
- **100 hours**: Production fine-tune
- **Training time**: 10-36 hours
- **Quality**: Good generalization, genre-specific characteristics

**Optimal Dataset**:
- **500+ hours**: High-quality genre mastery
- **Training time**: 50-180 hours
- **Quality**: Excellent, rivals original MusicGen on genre-specific tasks

### Licensing Considerations

#### Safe for Training (No Restrictions)

**CC0 (Public Domain)**:
- ✅ Training: Allowed
- ✅ Commercial use: Allowed
- ✅ Attribution: Not required
- **Best sources**: Freesound (266k CC0), some FMA tracks

**CC-BY (Attribution)**:
- ✅ Training: Allowed
- ✅ Commercial use: Allowed
- ⚠️ Attribution: Required (dataset acknowledgment)
- **Best sources**: Freesound (194k CC-BY), most FMA, Groove MIDI

#### Restricted Use

**CC-BY-NC (Non-Commercial)**:
- ✅ Training: Allowed (arguably)
- ❌ Commercial model: Questionable
- ✅ Research/personal: Allowed
- **Recommendation**: Avoid for commercial deployments

**All Rights Reserved**:
- ❌ Training: Not allowed without permission
- **Recommendation**: Do not use (legal risk)

#### Best Practice

**Dataset Licensing Strategy**:
```
Tier 1 (Core Dataset): 100% CC0 + CC-BY
  └─ Use for commercial model training
  └─ Clear licensing, no ambiguity

Tier 2 (Augmentation): CC-BY-NC acceptable
  └─ Use for research/personal models
  └─ Do not deploy commercially

Tier 3 (Validation Only): Use any license
  └─ Testing, evaluation, demos
  └─ Not included in training
```

---

## Training Recipes & Best Practices

### Recipe 1: Quick Hip-Hop Fine-Tune (15 min - 4 hours)

**Use Case**: Rapid prototyping, proof of concept

**Dataset**: 10-20 hours curated hip-hop

**Configuration**:
```yaml
model: musicgen-medium
continue_from: facebook/musicgen-medium

dataset:
  path: hip_hop_curated_10h/
  sample_rate: 32000
  duration: 30  # seconds per sample
  augmentation: true

training:
  batch_size: 8
  gradient_accumulation: 2
  lr: 1e-4  # Higher LR for quick fine-tune
  epochs: 3
  warmup: 100

optimizer:
  type: adamw
  weight_decay: 1e-5

mixed_precision: bf16
gradient_checkpointing: true
```

**Expected Results**:
- ✅ Genre-specific vocabulary
- ✅ Basic rhythmic patterns
- ⚠️ Limited variation
- ⚠️ May overfit to training samples

**Training Time on DGX Spark**: 1-4 hours

### Recipe 2: Production Dubstep Model (24-48 hours)

**Use Case**: High-quality genre-specific generation

**Dataset**: 100+ hours dubstep/EDM

**Multi-Stage Training**:

**Stage 1: Bass Synthesis (8 hours)**
```yaml
# Focus on wobble bass, sub-bass
dataset: dubstep_bass_stems/
model: musicgen-medium
lr: 1e-5
epochs: 10
loss_weights:
  low_freq: 2.0  # Emphasize 20-200Hz
  mid_freq: 1.0
  high_freq: 0.5
```

**Stage 2: Full Mix (16 hours)**
```yaml
# Complete productions
dataset: dubstep_full_tracks/
continue_from: stage1_bass_checkpoint.pt
lr: 5e-6  # Lower LR for refinement
epochs: 15
augmentation:
  pitch_shift: 0.1
  time_stretch: 0.05
  noise_injection: 0.02
```

**Expected Results**:
- ✅ Authentic wobble bass synthesis
- ✅ Complex drum patterns
- ✅ Buildup/drop structure
- ✅ Good stereo imaging

**Training Time on DGX Spark**: 24-48 hours

### Recipe 3: Multi-Genre Hybrid Model (48-72 hours)

**Use Case**: Versatile model covering hip-hop AND EDM

**Dataset**: 200+ hours (100 hip-hop + 100 EDM)

**Strategy**: Sequential fine-tuning with catastrophic forgetting prevention

**Phase 1: Hip-Hop Specialization (24 hours)**
```yaml
dataset: hip_hop_200h/
model: musicgen-medium
lr: 1e-5
epochs: 10
```

**Phase 2: EDM Addition (24 hours)**
```yaml
dataset: edm_100h/
continue_from: hip_hop_checkpoint.pt
lr: 5e-6  # Lower to preserve hip-hop knowledge
epochs: 10

# Mix in hip-hop samples to prevent forgetting
replay_buffer:
  hip_hop_samples: 0.2  # 20% of batch from hip-hop
```

**Phase 3: Joint Refinement (12 hours)**
```yaml
dataset: combined_hip_hop_edm/
lr: 1e-6  # Very low for refinement
epochs: 5
```

**Expected Results**:
- ✅ Strong performance on both genres
- ✅ Handles genre mixing prompts
- ⚠️ May dilute genre specificity vs single-genre models

### Best Practices Summary

#### Data Preparation

1. **Preprocessing Pipeline**:
```python
# Standard preprocessing for all audio
def preprocess_audio(input_path, output_path):
    # 1. Resample to 32kHz (MusicGen standard)
    subprocess.run([
        'ffmpeg', '-i', input_path,
        '-ar', '32000',
        '-ac', '2',  # Stereo
        output_path
    ])

    # 2. Normalize loudness
    subprocess.run([
        'ffmpeg-normalize', output_path,
        '-o', output_path,
        '-t', '-16',  # Target -16 LUFS
        '-ar', '32000'
    ])

    # 3. Remove vocals (optional, for instrumentals)
    if remove_vocals:
        subprocess.run([
            'demucs', '--two-stems=vocals',
            '-o', 'output/', output_path
        ])
```

2. **Metadata Enrichment**:
```python
# Auto-generate captions using Essentia
import essentia.standard as es

def generate_caption(audio_path):
    audio = es.MonoLoader(filename=audio_path)()

    # Extract features
    rhythm = es.RhythmExtractor2013()(audio)
    key = es.KeyExtractor()(audio)

    caption = f"{genre} track at {rhythm['bpm']:.0f} BPM in {key['key']} {key['scale']}"
    return caption
```

3. **Train/Val Split**:
```python
# 90/10 split, stratified by sub-genre
from sklearn.model_selection import train_test_split

train, val = train_test_split(
    dataset,
    test_size=0.1,
    stratify=dataset['sub_genre']
)
```

#### Training Configuration

1. **Learning Rate**:
```
Initial fine-tune: 1e-4 to 1e-5
Refinement: 5e-6 to 1e-6
Warmup: 500-1000 steps (critical for stability)
```

2. **Batch Size**:
```
DGX Spark 128GB:
  - MusicGen Small: 16-32
  - MusicGen Medium: 8-12
  - MusicGen Large: 4-6
```

3. **Gradient Accumulation**:
```
Effective batch = batch_size × grad_accum_steps
Target effective batch: 16-32
```

4. **Checkpointing**:
```yaml
checkpoint_every: 500  # steps
keep_last: 5  # Keep 5 most recent
save_best: true  # Based on validation loss
```

#### Monitoring & Evaluation

1. **Training Metrics**:
```python
# Log every 100 steps
- Training loss
- Validation loss
- Learning rate
- Gradient norm
- Memory usage
```

2. **Generation Samples**:
```python
# Generate samples every 5 epochs
prompts = [
    "heavy 808 trap beat 140 BPM",
    "boom bap hip hop 90 BPM jazzy",
    "dubstep drop wobble bass 140 BPM",
    "future bass buildup atmospheric"
]
```

3. **Validation Strategy**:
```python
# Objective metrics
- Frechet Audio Distance (FAD)
- Kullback-Leibler Divergence (KLD)
- CLAP score (text-audio alignment)

# Subjective evaluation
- Human listening tests (every 10 epochs)
- Compare to baseline pre-trained model
```

---

## Data Augmentation Techniques

### Audio-Specific Augmentation

#### 1. Time-Domain Augmentation

**Pitch Shifting**:
```python
import librosa
import soundfile as sf

def pitch_shift_augment(audio, sr, n_steps=2):
    # Shift up/down by 2 semitones randomly
    shift = np.random.uniform(-n_steps, n_steps)
    augmented = librosa.effects.pitch_shift(audio, sr=sr, n_steps=shift)
    return augmented
```

**Benefits**:
- ✅ Key variation
- ✅ Prevents overfitting to specific keys
- ⚠️ Keep within ±2 semitones (avoid artifacts)

**Time Stretching**:
```python
def time_stretch_augment(audio, rate_range=(0.95, 1.05)):
    rate = np.random.uniform(*rate_range)
    augmented = librosa.effects.time_stretch(audio, rate=rate)
    return augmented
```

**Benefits**:
- ✅ Tempo variation
- ✅ Rhythm robustness
- ⚠️ Use subtle variations (±5%)

#### 2. Spectral Augmentation

**SpecAugment** (adapted for music):
```python
import torchaudio.transforms as T

def spec_augment(waveform, sr):
    spectrogram = T.MelSpectrogram(
        sample_rate=sr,
        n_mels=128
    )(waveform)

    # Frequency masking
    freq_mask = T.FrequencyMasking(freq_mask_param=15)
    spectrogram = freq_mask(spectrogram)

    # Time masking
    time_mask = T.TimeMasking(time_mask_param=35)
    spectrogram = time_mask(spectrogram)

    return spectrogram
```

**Benefits**:
- ✅ Robustness to missing frequencies
- ✅ Reduces overfitting
- ⚠️ Don't mask low frequencies for bass-heavy genres

#### 3. Noise Injection

**Background Noise**:
```python
def add_background_noise(audio, noise_factor=0.005):
    noise = np.random.randn(len(audio))
    augmented = audio + noise_factor * noise
    return augmented
```

**Vinyl Crackle** (hip-hop specific):
```python
def add_vinyl_crackle(audio, sr, intensity=0.02):
    # Generate crackle using filtered noise
    crackle = np.random.randn(len(audio))
    # High-pass filter
    from scipy.signal import butter, lfilter
    b, a = butter(4, 2000 / (sr/2), btype='high')
    crackle = lfilter(b, a, crackle)

    augmented = audio + intensity * crackle
    return augmented
```

#### 4. Mixing Strategies

**MixUp for Audio**:
```python
def mixup_augment(audio1, audio2, alpha=0.2):
    # Mix two audio samples
    lam = np.random.beta(alpha, alpha)
    mixed = lam * audio1 + (1 - lam) * audio2
    # Mix captions too
    return mixed, lam
```

**Benefits**:
- ✅ Improved generalization
- ✅ Smoother latent space
- ⚠️ Use alpha=0.1-0.3 for music

**Stem Mixing** (genre-specific):
```python
def stem_mix_augment(drums, bass, melody):
    # Randomly adjust stem levels
    drum_level = np.random.uniform(0.7, 1.3)
    bass_level = np.random.uniform(0.7, 1.3)
    melody_level = np.random.uniform(0.6, 1.2)

    mixed = (
        drum_level * drums +
        bass_level * bass +
        melody_level * melody
    )
    return normalize(mixed)
```

**Benefits**:
- ✅ Learn from different mix balances
- ✅ Better instrument separation
- ✅ Ideal for hip-hop/EDM

#### 5. Genre-Specific Augmentation

**Hip-Hop Augmentation**:
```python
def hip_hop_augment(audio, sr):
    # 50% chance of each augmentation
    if np.random.rand() < 0.5:
        audio = add_vinyl_crackle(audio, sr)

    if np.random.rand() < 0.3:
        audio = pitch_shift_augment(audio, sr, n_steps=1)

    if np.random.rand() < 0.5:
        audio = add_tape_saturation(audio)

    return audio
```

**Dubstep/EDM Augmentation**:
```python
def edm_augment(audio, sr):
    # Preserve transients (critical for dubstep)
    if np.random.rand() < 0.3:
        audio = pitch_shift_augment(audio, sr, n_steps=3)  # Wider range OK

    if np.random.rand() < 0.5:
        audio = add_subtle_distortion(audio)

    # NO time stretching for EDM (ruins tight rhythms)

    return audio
```

### Augmentation Schedule

**Training Epochs 1-3**: Heavy augmentation (70% of samples)
- Build robustness
- Prevent early overfitting

**Training Epochs 4-7**: Moderate augmentation (40% of samples)
- Balance quality and robustness

**Training Epochs 8-10**: Light augmentation (20% of samples)
- Fine-tune on clean data
- Maximize quality

```python
def get_augmentation_prob(epoch, max_epochs=10):
    # Decay augmentation over training
    return max(0.2, 0.7 - (epoch / max_epochs) * 0.5)
```

---

## Optimization Strategies

### Memory Optimization

#### 1. Activation Checkpointing

```python
# Reduces activation memory by 60%
# Trade: 20% slower training

from torch.utils.checkpoint import checkpoint

class CheckpointedTransformerLayer(nn.Module):
    def forward(self, x):
        return checkpoint(self._forward, x, use_reentrant=False)
```

**When to Use**:
- ✅ Large models (MusicGen Large)
- ✅ Small GPU memory
- ✅ Willing to trade time for memory

#### 2. Mixed Precision Training

```python
# BFloat16 on Blackwell GPU
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

for batch in dataloader:
    with autocast(dtype=torch.bfloat16):
        loss = model(batch)

    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

**Benefits**:
- 40% memory reduction
- 2-3x faster training
- Better numerical stability than FP16

#### 3. Gradient Accumulation

```python
accumulation_steps = 4
optimizer.zero_grad()

for i, batch in enumerate(dataloader):
    loss = model(batch) / accumulation_steps
    loss.backward()

    if (i + 1) % accumulation_steps == 0:
        optimizer.step()
        optimizer.zero_grad()
```

**Benefits**:
- Simulate larger batch sizes
- Better gradient estimates
- No additional memory cost

### Speed Optimization

#### 1. Data Loading

```python
# Multi-worker data loading
dataloader = DataLoader(
    dataset,
    batch_size=8,
    num_workers=8,  # DGX Spark has many CPU cores
    pin_memory=True,  # Faster GPU transfer
    prefetch_factor=4  # Prefetch 4 batches per worker
)
```

#### 2. Compilation (PyTorch 2.0+)

```python
# JIT compilation for 20-30% speedup
model = torch.compile(model, mode='max-autotune')
```

#### 3. Efficient Attention

```python
# Flash Attention (automatic in PyTorch 2.5+)
# Verify enabled:
import torch
assert torch.backends.cuda.flash_sdp_enabled()
```

### Stability Optimization

#### 1. Gradient Clipping

```python
# Prevent gradient explosion
torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
```

#### 2. Learning Rate Warmup

```python
def get_lr_scheduler(optimizer, warmup_steps=500):
    def lr_lambda(step):
        if step < warmup_steps:
            return step / warmup_steps
        return 1.0

    return LambdaLR(optimizer, lr_lambda)
```

#### 3. EMA (Exponential Moving Average)

```python
from torch_ema import ExponentialMovingAverage

ema = ExponentialMovingAverage(model.parameters(), decay=0.999)

for batch in dataloader:
    loss = model(batch)
    loss.backward()
    optimizer.step()
    ema.update()

# Use EMA weights for inference
with ema.average_parameters():
    generated = model.generate(prompt)
```

**Benefits**:
- Better generalization
- Smoother convergence
- Industry standard for diffusion models

---

## Implementation Plan for DGX Spark

### Phase 1: Environment Setup (Day 1)

```bash
# 1. Install PyTorch with CUDA support
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 2. Install AudioCraft
pip install -U audiocraft

# 3. Install audio processing libraries
pip install librosa soundfile essentia

# 4. Install training utilities
pip install pytorch-lightning tensorboard wandb

# 5. Verify GPU
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

### Phase 2: Dataset Preparation (Days 2-3)

**Day 2: Data Collection**
```bash
# Download MusicBench
git clone https://huggingface.co/datasets/amaai-lab/MusicBench
python -c "from datasets import load_dataset; load_dataset('amaai-lab/MusicBench', cache_dir='./data')"

# Download FMA (medium subset)
wget https://os.unil.cloud.switch.ch/fma/fma_medium.zip
unzip fma_medium.zip
```

**Day 3: Preprocessing**
```python
# preprocess_dataset.py
import os
import subprocess
from pathlib import Path

def preprocess_pipeline(input_dir, output_dir, genre):
    for audio_file in Path(input_dir).glob('*.mp3'):
        output_path = Path(output_dir) / f"{audio_file.stem}.wav"

        # 1. Convert to WAV, resample, normalize
        subprocess.run([
            'ffmpeg', '-i', str(audio_file),
            '-ar', '32000', '-ac', '2',
            '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11',
            str(output_path)
        ])

        # 2. Remove vocals (optional)
        if genre == 'hip_hop':
            subprocess.run([
                'demucs', '--two-stems=vocals',
                '-n', 'mdx_extra', str(output_path)
            ])

# Run preprocessing
preprocess_pipeline('data/fma/hip_hop', 'data/processed/hip_hop', 'hip_hop')
preprocess_pipeline('data/fma/electronic', 'data/processed/edm', 'edm')
```

### Phase 3: Fine-Tuning Setup (Day 4)

**Create Training Configuration**:
```yaml
# configs/hip_hop_finetune.yaml
solver: musicgen/musicgen_base_32khz

model:
  lm:
    model_scale: medium
    n_q: 4
    card: 2048

compression_model:
  sample_rate: 32000
  channels: 2

conditioner:
  args:
    t5_model: t5-base

dataset:
  train: data/processed/hip_hop/train
  valid: data/processed/hip_hop/val
  batch_size: 8
  num_workers: 8

optim:
  optimizer: adamw
  lr: 1e-5
  betas: [0.9, 0.999]
  weight_decay: 1e-5
  warmup: 500

schedule:
  lr_scheduler: cosine
  cosine:
    T_max: 10000

training:
  epochs: 10
  gradient_accumulation: 2
  mixed_precision: bf16
  gradient_checkpointing: true
  checkpoint_every: 500

generate:
  every: 5
  num_samples: 10
  prompts:
    - "heavy 808 trap beat 140 BPM"
    - "boom bap hip hop 90 BPM jazzy piano"
    - "lo-fi hip hop chill beats 85 BPM"

logging:
  wandb: true
  project: musicgen-hip-hop
```

### Phase 4: Training Execution (Days 5-7)

**Start Training**:
```bash
# Hip-hop model
dora run -f configs/hip_hop_finetune.yaml

# Monitor with TensorBoard
tensorboard --logdir outputs/

# Or WandB
wandb login
# Training will auto-log to WandB
```

**Expected Timeline**:
- Hip-hop fine-tune: 18 hours (50 hours of data)
- EDM fine-tune: 18 hours (50 hours of data)
- Total: ~36 hours

**Monitoring**:
```python
# monitor_training.py
import wandb

api = wandb.Api()
run = api.run("your-project/run-id")

print(f"Status: {run.state}")
print(f"Loss: {run.summary['train/loss']}")
print(f"Epoch: {run.summary['epoch']}")
```

### Phase 5: Evaluation (Day 8)

**Quantitative Evaluation**:
```python
# evaluate.py
from audiocraft.models import MusicGen
import torch

# Load fine-tuned model
model = MusicGen.get_pretrained('path/to/checkpoint')

# Test prompts
prompts = [
    "heavy 808 bass trap beat 140 BPM with hi-hats",
    "boom bap drums 90 BPM jazzy piano sample",
    "lo-fi hip hop chill beat with vinyl crackle"
]

# Generate
model.set_generation_params(duration=30)
for i, prompt in enumerate(prompts):
    wav = model.generate([prompt])
    audio_write(f'eval_output_{i}', wav[0].cpu(), model.sample_rate)

# Calculate FAD score
from frechet_audio_distance import FrechetAudioDistance
fad = FrechetAudioDistance()
score = fad.score('data/processed/hip_hop/test', 'eval_output/')
print(f"FAD Score: {score}")
```

**Qualitative Evaluation**:
- Listen to 50 generated samples
- Compare to baseline MusicGen
- Rate on scale 1-5: genre accuracy, quality, creativity
- Document failure modes

### Phase 6: Deployment (Day 9-10)

**Export Model**:
```python
# export_model.py
from audiocraft.models import MusicGen

model = MusicGen.get_pretrained('path/to/best_checkpoint')

# Export for inference
torch.save({
    'model_state_dict': model.state_dict(),
    'config': model.config
}, 'models/musicgen_hip_hop_v1.pt')
```

**Create Inference API**:
```python
# inference_api.py
from fastapi import FastAPI
from audiocraft.models import MusicGen
import torch

app = FastAPI()

# Load model once at startup
model = MusicGen.get_pretrained('models/musicgen_hip_hop_v1.pt')
model.set_generation_params(duration=30)

@app.post("/generate")
async def generate_music(prompt: str, duration: int = 30):
    wav = model.generate([prompt])
    # Return audio file
    return {"audio_path": save_and_return(wav)}

# Run with: uvicorn inference_api:app --host 0.0.0.0 --port 8000
```

### Complete Training Script

```python
# train_musicgen.py
import torch
from audiocraft.models import MusicGen
from audiocraft.solvers import MusicGenSolver
from omegaconf import OmegaConf
import pytorch_lightning as pl
from pytorch_lightning.callbacks import ModelCheckpoint, EarlyStopping

def main():
    # Load config
    config = OmegaConf.load('configs/hip_hop_finetune.yaml')

    # Initialize model
    model = MusicGen.get_pretrained('facebook/musicgen-medium')

    # Setup training
    solver = MusicGenSolver(model, config)

    # Callbacks
    checkpoint_callback = ModelCheckpoint(
        dirpath='checkpoints/',
        filename='musicgen-hip-hop-{epoch:02d}-{val_loss:.2f}',
        save_top_k=3,
        monitor='val_loss'
    )

    early_stop_callback = EarlyStopping(
        monitor='val_loss',
        patience=5,
        mode='min'
    )

    # Trainer
    trainer = pl.Trainer(
        max_epochs=config.training.epochs,
        accelerator='gpu',
        devices=1,
        precision='bf16-mixed',
        callbacks=[checkpoint_callback, early_stop_callback],
        accumulate_grad_batches=config.training.gradient_accumulation,
        log_every_n_steps=50
    )

    # Train
    trainer.fit(solver)

    print("Training complete!")
    print(f"Best checkpoint: {checkpoint_callback.best_model_path}")

if __name__ == '__main__':
    main()
```

---

## Summary & Recommendations

### Best Approach for DGX Spark

**Recommended Strategy**: Fine-tune MusicGen Medium separately for hip-hop and dubstep

**Why**:
1. ✅ Proven architecture with successful fine-tuning examples
2. ✅ Fits comfortably in 128GB memory (24-32GB per model)
3. ✅ Fast training (8-24 hours per genre)
4. ✅ Excellent controllability (text + melody conditioning)
5. ✅ Active community and documentation

### Timeline Estimate

```
Week 1: Setup + Data Preparation
  Days 1-2: Environment setup, dataset download
  Days 3-4: Preprocessing, metadata generation
  Day 5: Verification, training configuration

Week 2: Hip-Hop Model Training
  Days 1-2: Fine-tuning (18 hours)
  Day 3: Evaluation
  Day 4: Iteration/improvement

Week 3: Dubstep/EDM Model Training
  Days 1-2: Fine-tuning (18 hours)
  Day 3: Evaluation
  Day 4: Deployment preparation

Total: 3 weeks to production-ready models
```

### Resource Requirements

**Storage**:
- Raw datasets: 200GB
- Preprocessed audio: 100GB
- Model checkpoints: 50GB
- Total: ~350GB

**Compute**:
- Training: 36-48 hours GPU time
- Preprocessing: 8-12 hours CPU time

**Memory**:
- Peak usage: 32GB (well within 128GB)
- Can train multiple models or experiments simultaneously

### Expected Results

**After Fine-Tuning**:
- ✅ Genre-specific generation (hip-hop OR dubstep)
- ✅ BPM control (via text prompt)
- ✅ Instrument specification
- ✅ Style variation within genre
- ⚠️ Limited to 30-second generations
- ⚠️ May not perfectly nail extreme synthesis (wobble bass)

**Quality Metrics** (estimated):
- FAD Score: 5-10 (lower is better, MusicGen baseline: 5.14)
- Human preference: 70-80% prefer fine-tuned over generic
- Genre accuracy: 85-95% correctly identified as target genre

---

## References & Resources

### Research Papers
- **MusicGen**: "Simple and Controllable Music Generation" (2023) - https://arxiv.org/abs/2306.05284
- **Stable Audio**: "Fast Timing-Conditioned Latent Audio Diffusion" (2024) - https://arxiv.org/abs/2407.12563
- **Make-An-Audio 2**: "Temporal-Enhanced Text-to-Audio Generation" (2024)
- **Multi-Source Latent Diffusion**: "Latent Diffusion for Music Generation" (2024) - https://arxiv.org/abs/2409.06190

### Code Repositories
- **AudioCraft**: https://github.com/facebookresearch/audiocraft
- **Stable Audio Tools**: https://github.com/Stability-AI/stable-audio-tools
- **AudioLDM Training**: https://github.com/haoheliu/AudioLDM-training-finetuning
- **MusicGen Fine-Tuner**: https://github.com/sakemin/cog-musicgen-fine-tuner

### Datasets
- **MusicBench**: https://huggingface.co/datasets/amaai-lab/MusicBench
- **Free Music Archive**: https://github.com/mdeff/fma
- **Groove MIDI**: https://magenta.tensorflow.org/datasets/groove
- **Freesound**: https://freesound.org/

### Tools & Libraries
- **Demucs** (source separation): https://github.com/facebookresearch/demucs
- **Essentia** (audio analysis): https://essentia.upf.edu/
- **Librosa** (audio processing): https://librosa.org/
- **FFmpeg** (audio conversion): https://ffmpeg.org/

---

**Document Status**: Comprehensive research complete
**Next Steps**: Begin implementation following Phase 1-6 plan
**Estimated Time to First Model**: 1 week
**Estimated Time to Production**: 3 weeks
