
#ubuntu
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV GIT_SSL_NO_VERIFY=1
ENV FORCE_UNSAFE_CONFIGURE=1

#RUN sed -i s:/archive.ubuntu.com:/mirrors.tuna.tsinghua.edu.cn/ubuntu:g /etc/apt/sources.list
#RUN apt-get clean

RUN apt-get -y update --fix-missing && \
    apt-get install -y \
    ecj \
    git \
    vim \
    npm \
    g++ \
    gcc \
    file \
    swig \
    wget \
    time \
    make \
    curl \
    cmake \
    gawk \
    unzip \
    rsync \
    ccache \
    fastjar \
    gettext \
    xsltproc \
    apt-utils \
    libssl-dev \
    libelf-dev \
    zlib1g-dev \
    subversion \
    build-essential \
    libncurses5-dev \
    libncursesw5-dev \
    python \
    python3 \
    python3-dev \
    python2.7-dev \
    python3-setuptools \
    python-distutils-extra \
    java-propose-classpath \
    && apt-get clean

RUN npm cache clean -f && \
    npm install -g n && \
    n stable && \
    /bin/bash && \
    node -v

RUN npm install -g npm@8.19.2 &&\
    /bin/bash && \
    npm -v

WORKDIR /home

RUN git clone -b openwrt-19.07 --recursive https://github.com/openwrt/openwrt.git

WORKDIR /home/openwrt

RUN ./scripts/feeds update -a \
    && ./scripts/feeds install -a \
    && rm -rf feeds/packages/net/nginx package/feeds/packages/nginx

RUN echo "src-git oui https://github.com/jorislee/oui.git" >> feeds.conf.default \
    && ./scripts/feeds update oui \
    && ./scripts/feeds install -a oui

COPY ./HLK-7621A.dts ./target/linux/ramips/dts/HLK-7621A.dts
COPY ./mt7621.mk ./target/linux/ramips/image/mt7621.mk

RUN rm -f .config* && touch .config && \
    echo "CONFIG_HOST_OS_LINUX=y" >> .config && \
    echo "CONFIG_TARGET_ramips=y" >> .config && \
    echo "CONFIG_TARGET_ramips_mt7621=y" >> .config && \
    echo "CONFIG_TARGET_ramips_mt7621_DEVICE_mediatek_hlk-7621a=y" >> .config && \
    echo "CONFIG_TARGET_ROOTFS_INITRAMFS=y" >> .config && \
    echo "CONFIG_SDK=y" >> .config && \
    echo "CONFIG_MAKE_TOOLCHAIN=y" >> .config && \
    echo "CONFIG_IB=y" >> .config && \
    echo "CONFIG_PACKAGE_vim=y" >> .config && \
    echo "CONFIG_PACKAGE_bash=y" >> .config && \
    echo "CONFIG_PACKAGE_wget=y" >> .config && \
    echo "CONFIG_PACKAGE_ethtool=y" >> .config && \
    echo "CONFIG_PACKAGE_oui-rpc-core=y" >> .config && \
    echo "CONFIG_PACKAGE_oui-ui-core=y" >> .config && \
    echo "CONFIG_OUI_USE_HOST_NODE=y" >> .config && \
    sed -i 's/^[ \t]*//g' .config && \
    make defconfig

RUN make download -j8 \
    && make -j1 V=w \
    && rm -rf ./build_dir/toolchain-mipsel_24kc_gcc-7.5.0_musl/ ./build_dir/host/ ./build_dir/hostpkg/ \
    && cp ./bin/targets/ramips/mt7621/openwrt-toolchain-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.bz2 /opt \
    && cp ./bin/targets/ramips/mt7621/openwrt-imagebuilder-ramips-mt7621.Linux-x86_64.tar.xz /home \
    && cd /opt \
    && tar -jxvf openwrt-toolchain-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.bz2 \
    && rm openwrt-toolchain-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.bz2 \
    && cd /home \
    && tar -J -x -f openwrt-imagebuilder-ramips-mt7621.Linux-x86_64.tar.xz \
    && rm openwrt-imagebuilder-ramips-mt7621.Linux-x86_64.tar.xz \
    && cd /home/openwrt \
    && rm -rf ./bin/

ENV STAGING_DIR=/opt/openwrt-toolchain-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin
WORKDIR /home/openwrt-imagebuilder-ramips-mt7621.Linux-x86_64

RUN make image PROFILE="mediatek_hlk-mt7621a" PACKAGES="wget vim bash"

WORKDIR /home
CMD [ "/bin/bash" ]
