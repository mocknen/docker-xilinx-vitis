# syntax=docker/dockerfile:1.4

ARG product=Vitis
ARG edition='Vitis Unified Software Platform'
ARG destination=/opt/xilinx
ARG extract_dir=/tmp/xilinx


FROM ubuntu:jammy AS base-image


FROM base-image AS install

SHELL ["/bin/bash", "-euc"]

RUN <<EOT
declare -a packages
packages+=(file)
packages+=(libtinfo5)
packages+=(libx11-6)
packages+=(locales)
packages+=(python3)
packages+=(xz-utils)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "${packages[@]}"
rm -rf /var/lib/apt/lists/*
localedef -i en_US -f UTF-8 en_US.UTF-8
EOT


FROM base-image AS extract-2023-1

ARG md5=f2011ceba52b109e3551c1d3189a8c9c
ARG source=Xilinx_Unified_2023.1_0507_1903.tar.gz
ARG target=/tmp/$source
ARG extract_dir

WORKDIR $extract_dir

SHELL ["/bin/bash", "-euc"]

RUN --mount=type=bind,source=$source,target=$target <<EOF
md5sum -c --strict <<<"$md5  $target"
tar xf "$target" --strip-components=1
EOF


FROM install AS install-2023-1

ARG product
ARG edition
ARG destination
ARG extract_dir

COPY --link --from=extract-2023-1 $extract_dir $extract_dir

WORKDIR $extract_dir

SHELL ["/bin/bash", "-euco", "pipefail"]

RUN <<EOT
cat <<EOF | ./xsetup -a XilinxEULA,3rdPartyEULA -b Install -c <(cat)
Product=$product
Edition=$edition
Destination=$destination
CreateProgramGroupShortcuts=0
CreateShortcutsForAllUsers=0
CreateDesktopShortcuts=0
CreateFileAssociation=0
EnableDiskUsageOptimization=1
EOF
EOT


FROM install AS exec

SHELL ["/bin/bash", "-euc"]

RUN <<EOT
declare -a packages
packages+=(g++)
packages+=(git)
packages+=(graphviz)
packages+=(libc6-dev-i386)
packages+=(libncursesw5)
packages+=(make)
packages+=(net-tools)
packages+=(unzip)
packages+=(xvfb)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "${packages[@]}"
rm -rf /var/lib/apt/lists/*
EOT


FROM exec AS final

ARG destination
ARG version=2023.1

ENV XILINX_VIVADO=$destination/Vivado/$version
ENV XILINX_VITIS=$destination/Vitis/$version
ENV XILINX_HLS=$destination/Vitis_HLS/$version
ENV PATH=$destination/DocNav:$PATH
ENV PATH=$destination/Vivado/$version/bin:$PATH
ENV PATH=$destination/Vitis/$version/aietools/bin:$PATH
ENV PATH=$destination/Vitis/$version/tps/lnx64/cmake-3.3.2/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/armr5/lin/gcc-arm-none-eabi/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/aarch64/lin/aarch64-none/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/aarch64/lin/aarch64-linux/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/aarch32/lin/gcc-arm-none-eabi/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/microblaze/linux_toolchain/lin64_le/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/arm/lin/bin:$PATH
ENV PATH=$destination/Vitis/$version/gnu/microblaze/lin/bin:$PATH
ENV PATH=$destination/Vitis/$version/bin:$PATH
ENV PATH=$destination/Model_Composer/$version/bin:$PATH
ENV PATH=$destination/Vitis_HLS/$version/bin:$PATH

COPY --link --from=install-2023-1 $destination $destination
