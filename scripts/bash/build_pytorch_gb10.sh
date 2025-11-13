#!/usr/bin/env bash
# Build PyTorch from source with NVIDIA GB10 (Blackwell) support
# Prerequisites: Run setup_pytorch_build.sh first
#
# Usage: bash scripts/bash/build_pytorch_gb10.sh

set -euo pipefail

PYTORCH_DIR="${HOME}/pytorch-build"
# Use project venv if available, otherwise system python
if [ -f "/home/beengud/raibid-labs/dgx-music/venv/bin/python3" ]; then
    PYTHON_BIN="/home/beengud/raibid-labs/dgx-music/venv/bin/python3"
    PIP_BIN="/home/beengud/raibid-labs/dgx-music/venv/bin/pip"
else
    PYTHON_BIN="$(which python3)"
    PIP_BIN="$(which pip3)"
fi

echo "============================================================"
echo "PyTorch Build for NVIDIA GB10 (Blackwell - Compute 12.1)"
echo "============================================================"
echo ""
echo "Build directory: $PYTORCH_DIR"
echo "Python: $PYTHON_BIN"
echo ""

# Create build directory
mkdir -p "$PYTORCH_DIR"
cd "$PYTORCH_DIR"

# Clone PyTorch if not already cloned
if [ ! -d "pytorch" ]; then
    echo "Step 1: Cloning PyTorch repository..."
    git clone --recursive https://github.com/pytorch/pytorch
    cd pytorch

    # Checkout latest stable (or specify version)
    git checkout v2.9.0  # or main for latest
    git submodule sync
    git submodule update --init --recursive
    echo "✅ PyTorch cloned"
else
    echo "Step 1: PyTorch already cloned, verifying checkout..."
    cd pytorch
    git checkout v2.9.0
    git submodule sync
    git submodule update --init --recursive
    echo "✅ PyTorch ready (v2.9.0)"
fi

echo ""
echo "Step 2: Configuring build environment..."

# Set CUDA paths
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}

# Configure PyTorch build for GB10
export USE_CUDA=1
export USE_CUDNN=1
export USE_NCCL=0  # Disable NCCL (distributed training)

# CRITICAL: Set CUDA architecture for GB10 (Blackwell)
# GB10 has compute capability 12.1
export TORCH_CUDA_ARCH_LIST="12.1"

# Optional optimizations
export USE_NINJA=0  # Set to 1 if ninja is installed
export BUILD_TEST=0  # Skip building tests to save time
export USE_FBGEMM=0  # Skip Facebook GEMM (not needed for music generation)
export USE_KINETO=0  # Skip profiling library
export USE_DISTRIBUTED=0  # Skip distributed training features
export USE_FLASH_ATTENTION=0  # Disable flash attention (failing on GB10)
export USE_XNNPACK=0  # Disable XNNPACK (failing build)
export MAX_JOBS=4  # Limit parallel jobs to reduce memory pressure

# Use ccache if available
if command -v ccache &> /dev/null; then
    export CC="ccache gcc"
    export CXX="ccache g++"
    echo "✅ Using ccache for faster rebuilds"
fi

echo "✅ Build environment configured"
echo ""
echo "Build configuration:"
echo "  CUDA_HOME: $CUDA_HOME"
echo "  USE_CUDA: $USE_CUDA"
echo "  TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
echo "  Python: $PYTHON_BIN"
echo ""

# Install Python dependencies
echo "Step 3: Installing Python build dependencies..."
$PIP_BIN install --upgrade pip
# Note: MKL is x86_64 only, ARM64 uses OpenBLAS (already installed via apt)
$PIP_BIN install numpy pyyaml setuptools cmake cffi typing_extensions

echo "✅ Python dependencies installed"
echo ""

# Build PyTorch
echo "Step 4: Building PyTorch..."
echo "⚠️  This will take 2-4 hours on DGX Spark"
echo "⚠️  Monitor CPU/memory usage during build"
echo ""
echo "Starting build at $(date)"
echo ""

# Run the build
$PYTHON_BIN setup.py clean  # Clean previous builds
time $PYTHON_BIN setup.py install 2>&1 | tee pytorch_build.log

echo ""
echo "Build completed at $(date)"
echo ""

# Verify installation
echo "Step 5: Verifying PyTorch installation..."
$PYTHON_BIN -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('CUDA version:', torch.version.cuda); print('GPU count:', torch.cuda.device_count()); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')"

echo ""
echo "============================================================"
echo "PyTorch Build Complete!"
echo "============================================================"
echo ""
echo "Build log saved to: $PYTORCH_DIR/pytorch/pytorch_build.log"
echo ""
echo "Next steps:"
echo "  1. Test GPU: python3 -c 'import torch; print(torch.cuda.is_available())'"
echo "  2. Run validation: python3 scripts/bash/validate_gpu.py"
echo "  3. Benchmark: python3 scripts/bash/benchmark_generation.py"
echo ""
echo "If build succeeded, PyTorch is now installed in your Python environment"
echo "with full NVIDIA GB10 (Blackwell) GPU support!"
echo "============================================================"
