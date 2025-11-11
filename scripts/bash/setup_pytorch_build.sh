#!/usr/bin/env bash
# Setup script for building PyTorch from source on DGX Spark
# Run with: sudo bash scripts/bash/setup_pytorch_build.sh

set -euo pipefail

echo "============================================================"
echo "PyTorch Build Environment Setup for DGX Spark (ARM64+CUDA)"
echo "============================================================"
echo ""

# Install build dependencies
echo "Step 1: Installing build dependencies..."
apt-get update
apt-get install -y \
    build-essential \
    cmake \
    git \
    libopenblas-dev \
    libblas-dev \
    liblapack-dev \
    ninja-build \
    ccache \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel

echo "✅ Build dependencies installed"
echo ""

# Set up ccache for faster rebuilds
echo "Step 2: Configuring ccache..."
ccache --max-size=10G
ccache --set-config=compression=true

echo "✅ ccache configured"
echo ""

echo "============================================================"
echo "Build environment ready!"
echo "============================================================"
echo ""
echo "Next steps:"
echo "  1. Clone PyTorch: git clone --recursive https://github.com/pytorch/pytorch"
echo "  2. Configure build: export TORCH_CUDA_ARCH_LIST=\"12.1\" USE_CUDA=1"
echo "  3. Build: python3 setup.py install"
echo ""
echo "Estimated build time: 2-4 hours on DGX Spark"
echo "============================================================"
