# CUDA Setup for ARM64 (DGX Spark)

**Date:** November 10, 2025
**Hardware:** NVIDIA DGX Spark (ARM64/aarch64)
**GPU:** NVIDIA GB10
**CUDA Version:** 13.0

---

## Hardware Validation Results

### ✅ Confirmed Working
- **GPU Detected:** NVIDIA GB10 via `nvidia-smi`
- **CUDA Installed:** CUDA 13.0 (Driver 580.95.05)
- **CUDA Libraries:** Present in `/usr/local/cuda/targets/sbsa-linux/lib/`
- **CUDA Compiler:** `nvcc` available at `/usr/local/cuda/bin/nvcc`
- **Architecture:** ARM64 (aarch64) - DGX Spark native

### ❌ Critical Issue
- **PyTorch:** Only CPU-only wheels available for ARM64
- **Root Cause:** PyTorch does not provide pre-built ARM64+CUDA wheels through PyPI
- **Impact:** Cannot use GPU acceleration with standard PyTorch installation

---

## The ARM64+CUDA PyTorch Problem

PyTorch's official distribution channels (PyPI, pip) **do not provide ARM64 wheels with CUDA support**. This is a known limitation affecting all ARM64 NVIDIA platforms including:
- NVIDIA Jetson devices
- NVIDIA Grace Hopper systems
- NVIDIA DGX Spark (our platform)

### Why This Happens
1. PyTorch primarily targets x86_64 architecture
2. ARM64+CUDA wheels require platform-specific compilation
3. NVIDIA provides these wheels through their own channels (NGC, JetPack)

---

## Solutions (Choose One)

### Option 1: Build PyTorch from Source ⚙️

**Pros:**
- Full CUDA support with latest PyTorch
- Optimized for your specific hardware
- No dependency on external images

**Cons:**
- Takes 2-4 hours to compile
- Requires significant disk space (~15GB during build)
- Complex build process with many dependencies

**Steps:**
```bash
# Install build dependencies
sudo apt-get update
sudo apt-get install -y build-essential cmake git \
    libopenblas-dev libblas-dev liblapack-dev

# Clone PyTorch
git clone --recursive https://github.com/pytorch/pytorch
cd pytorch
git checkout v2.9.0  # or latest stable

# Set CUDA environment
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Build PyTorch with CUDA
export USE_CUDA=1
export USE_CUDNN=1
export TORCH_CUDA_ARCH_LIST="9.0"  # For GB10 GPU
python3 setup.py install
```

**Estimated Time:** 2-4 hours on DGX Spark

---

### Option 2: Use NVIDIA NGC Container 🐳 (RECOMMENDED)

**Pros:**
- Pre-built PyTorch with CUDA support
- Optimized by NVIDIA for ARM64
- Ready to use immediately
- Includes all necessary dependencies

**Cons:**
- Requires Docker/Podman
- Application runs in container (requires Docker workflow changes)

**Steps:**
```bash
# Pull NVIDIA PyTorch container for ARM64
docker pull nvcr.io/nvidia/pytorch:25.11-py3-arm64

# Run with GPU support
docker run --gpus all -it --rm \
    -v $(pwd):/workspace \
    nvcr.io/nvidia/pytorch:25.11-py3-arm64

# Inside container, PyTorch+CUDA is ready
python3 -c "import torch; print(torch.cuda.is_available())"  # Should print True
```

**Adaptation for DGX Music:**
- Update Tiltfile to use NGC container
- Mount project directory into container
- Expose port 8000 for API access
- All commands run inside container

**Estimated Time:** 30 minutes (pull + setup)

---

### Option 3: CPU Fallback (Demo/Testing Only) 💻

**Pros:**
- Already installed and working
- No setup required
- Good for development/testing non-GPU code

**Cons:**
- 5-10x slower generation (60-300s vs <30s target)
- Not suitable for production
- May hit memory constraints with larger models

**Current Status:**
```bash
# Already working
source venv/bin/activate
python3 -c "import torch; print(torch.__version__)"
# Output: 2.9.0+cpu
```

**Use Cases:**
- API/database development
- Testing non-generation endpoints
- Integration testing with mock generation
- CLI interface development

**NOT suitable for:**
- Performance benchmarking
- Production music generation
- Model quality evaluation

---

### Option 4: Cloud GPU Hybrid ☁️

**Pros:**
- Keeps DGX Spark for API/storage/orchestration
- Uses proven x86_64 GPU instances for generation
- No local CUDA issues
- Scalable

**Cons:**
- Adds 500ms-1s latency per generation
- Ongoing cloud costs (~$0.50-1.00/GPU hour)
- Requires network connectivity
- More complex architecture

**Implementation:**
- Modify `services/generation/engine.py` to call remote GPU API
- Options: RunPod, Replicate, AWS SageMaker, Modal
- DGX Spark remains primary API/database server

**Estimated Time:** 1-2 days integration

---

## Recommendation

**For MVP Development:** Option 2 (NGC Container)

**Rationale:**
1. **Fastest path to GPU:** 30 minutes vs 2-4 hours (build from source)
2. **NVIDIA-optimized:** Built specifically for ARM64 NVIDIA platforms
3. **Production-ready:** Same containers used in NVIDIA's production deployments
4. **Minimal code changes:** Update Tiltfile and deployment scripts

**For Production:** Option 2 or Option 4

**Rationale:**
- Option 2 if running on DGX Spark hardware
- Option 4 if need to scale beyond single GPU or want flexibility

---

## Implementation: NGC Container Approach

### 1. Install Docker (if not present)
```bash
# Check if Docker is installed
docker --version

# If not, install
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and log back in
```

### 2. Install NVIDIA Container Toolkit
```bash
# Add NVIDIA's GPG key
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 3. Pull NGC PyTorch Container
```bash
docker pull nvcr.io/nvidia/pytorch:25.11-py3-arm64
```

### 4. Test GPU Access
```bash
docker run --gpus all --rm nvcr.io/nvidia/pytorch:25.11-py3-arm64 \
    python3 -c "import torch; print('CUDA:', torch.cuda.is_available()); print('GPU:', torch.cuda.get_device_name(0))"

# Expected output:
# CUDA: True
# GPU: NVIDIA GB10
```

### 5. Update Project for Container

**Create `docker/Dockerfile.dgx-music`:**
```dockerfile
FROM nvcr.io/nvidia/pytorch:25.11-py3-arm64

WORKDIR /workspace

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose API port
EXPOSE 8000

# Run API server
CMD ["uvicorn", "services.generation.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Update `Tiltfile`:**
```python
# Build with NGC base image
docker_build(
    ref='dgx-music-generation',
    context='.',
    dockerfile='./docker/Dockerfile.dgx-music',
)

# Deploy with GPU support
k8s_resource(
    'dgx-music-generation',
    resource_deps=['nvidia-device-plugin'],  # Ensure GPU available
)
```

### 6. Validate Setup
```bash
# Build image
docker build -f docker/Dockerfile.dgx-music -t dgx-music .

# Run with GPU
docker run --gpus all -p 8000:8000 dgx-music

# Test API (in another terminal)
curl http://localhost:8000/health
```

---

## Testing GPU Performance

Once GPU is working, run the benchmark:

```bash
# Inside container or with CUDA-enabled PyTorch
source venv/bin/activate
python3 scripts/bash/benchmark_generation.py

# Expected output:
# ✅ MusicGen Small loaded
# ✅ Generation completed
# ⏱️ Time: ~20-25s for 16s audio
# 💾 Memory: ~8-12GB GPU
```

---

## Current Status

- ✅ GPU detected and working (nvidia-smi confirms)
- ✅ CUDA 13.0 installed
- ❌ PyTorch only available with CPU support
- ⏸️ Awaiting decision on implementation path

---

## Next Steps

**Choose your path:**

1. **Quick Demo (today):** Use Option 3 (CPU) to test API/database, accept slow generation
2. **Full MVP (this week):** Implement Option 2 (NGC Container) for GPU support
3. **Production (next week):** Option 2 for on-prem or Option 4 for cloud hybrid

**Recommended:** Start with Option 2 (NGC Container) - provides best balance of time vs functionality.

---

## References

- [PyTorch on NVIDIA Jetson](https://forums.developer.nvidia.com/t/pytorch-for-jetson)
- [NGC PyTorch Container](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch)
- [Building PyTorch from Source](https://github.com/pytorch/pytorch#from-source)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)

---

**Document Status:** Ready for implementation
**Owner:** DGX Music Engineering Team
**Last Updated:** November 10, 2025
