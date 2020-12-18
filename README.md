# Pre-built libtorch for ARM32/64 Systems

## NVIDIA Drive PX2

The pre-built package is `./https://github.com/wangkuiyi/pytorch-rpi.zip`.

The steps to build it include:

1. Log in to an NVIDIA Drive PX2 computer.
1. Upgrade the system from Ubuntu 16.04 to Ubuntu 18.04 for a recent Python.
1. Install Clang with `sudo apt-get install -y clang`.
1. Set environment variables:
   ```bash
   export USE_CUDA=0
   export USE_QNNPACK=0
   export USE_PYTORCH_QNNPACK=0
   ```
1. Run `./build_libtorch.sh` to build and pack the zip file.

## Raspberry Pi (32-bit)

1. Install the latest Raspberry Pi OS (32-bit).
1. Run `sudo apt update && sudo apt upgrade`.
1. Run `git clone git@github.com:ljk53/pytorch-rpi && cd pytorch-rpi`.
1. Run `LIBTORCH_VARIANT=armv7l-cxx11-abi-shared-without-deps ./build_libtorch.sh`.

## Raspberry Pi (64-bit)

1. Install the latest 64-bit Ubuntu 20.04 for Raspberry Pi.
1. Run `sudo apt update && sudo apt upgrade`.
1. Run `git clone git@github.com:ljk53/pytorch-rpi && cd pytorch-rpi`.
1. Run `MAX_JOBS=2 LIBTORCH_VARIANT=aarch64-cxx11-abi-shared-without-deps ./build_libtorch.sh`.
   Note: set the max number of concurrent build jobs to 2 to avoid running out of the RAM.
