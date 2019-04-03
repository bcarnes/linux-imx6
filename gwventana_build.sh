#!/bin/bash
set -euxo pipefail

check_installed() {
    needed=()
    for pkg; do
	if ! dpkg -s "${pkg}" &>/dev/null; then
	    needed+=("${pkg}")
	fi
    done
    if (( ${#needed[@]} )); then
	echo "Missing dependencies:"
	echo "  apt-get install -y ${needed[@]}"
	return 1
    fi
}
    
prereqs=(
  bc
  bison
  build-essential
  flex
  gcc-arm-linux-gnueabihf
  git
  libssl-dev
  liblzo2-dev
  lzop
  libncurses5-dev
  u-boot-tools
)

check_installed "${prereqs[@]}"

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
export INSTALL_MOD_PATH=install
export INSTALL_HDR_PATH=install/usr
export LOADADDR=0x10008000

mkdir -p install/{boot,lib,usr}

make gwventana_defconfig
./scripts/config --enable BTRFS_FS

make -j$(nproc) uImage dtbs
make -j$(nproc) modules

make INSTALL_MOD_PATH=install modules_install \
     INSTALL_HDR_PATH=install/usr headers_install

cp arch/arm/boot/uImage arch/arm/boot/dts/imx6*-gw*.dtb gwventana_bootscript \
   install/boot/

mkimage -A arm -O linux -T script -n bootscript \
  -d gwventana_bootscript install/boot/6x_bootscript-ventana
