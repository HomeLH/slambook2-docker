FROM ubuntu:18.04
COPY ./sources.list /etc/apt

ENV DEBCONF_NOWARNINGS yes
RUN DEBIAN_FRONTEND=noninteractivea \
	set -x && apt-get update -y -qq && \
#	 "basic dependencies"
	apt-get install -y -qq build-essential \
	pkg-config \
	git \
	wget \
	curl \
	tar \
	unzip \
	cmake \
	vim \ 
# Eigen dependencies
	libeigen3-dev \
# Pangolin dependencies
	libgl1-mesa-dev \
	libglew-dev && \
	apt-get autoremove -y -qq && \
	rm -rf /var/lib/apt/lists/*

COPY ./3rdparty /opt/slambook/3rdparty


ARG CMAKE_INSTALL_PREFIX=/usr/local
ARG NUM_THREADS=4

ENV CPATH=${CMAKE_INSTALL_PREFIX}/include:${CPATH}
ENV C_INCLUDE_PATH=${CMAKE_INSTALL_PREFIX}/include:${C_INCLUDE_PATH}
ENV CPLUS_INCLUDE_PATH=${CMAKE_INSTALL_PREFIX}/include:${CPLUS_INCLUDE_PATH}
ENV LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib:${LD_LIBRARY_PATH}

# build Pangolin
WORKDIR /opt/slambook/3rdparty/Pangolin
RUN set -x && \
  mkdir -p build && \
  cd build && \
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_PANGOLIN_DEPTHSENSE=OFF \
    -DBUILD_PANGOLIN_FFMPEG=OFF \
    -DBUILD_PANGOLIN_LIBDC1394=OFF \
    -DBUILD_PANGOLIN_LIBJPEG=OFF \
    -DBUILD_PANGOLIN_LIBOPENEXR=OFF \
    -DBUILD_PANGOLIN_LIBPNG=OFF \
    -DBUILD_PANGOLIN_LIBREALSENSE=OFF \
    -DBUILD_PANGOLIN_LIBREALSENSE2=OFF \
    -DBUILD_PANGOLIN_LIBTIFF=OFF \
    -DBUILD_PANGOLIN_LIBUVC=OFF \
    -DBUILD_PANGOLIN_OPENNI=OFF \
    -DBUILD_PANGOLIN_OPENNI2=OFF \
    -DBUILD_PANGOLIN_PLEORA=OFF \
    -DBUILD_PANGOLIN_PYTHON=OFF \
    -DBUILD_PANGOLIN_TELICAM=OFF \
    -DBUILD_PANGOLIN_TOON=OFF \
    -DBUILD_PANGOLIN_UVC_MEDIAFOUNDATION=OFF \
    -DBUILD_PANGOLIN_V4L=OFF \
    -DBUILD_PANGOLIN_VIDEO=OFF \
    -DBUILD_PANGOLIN_ZSTD=OFF \
    -DBUILD_PYPANGOLIN_MODULE=OFF \
    .. && \
  make -j${NUM_THREADS} && \
  make install && \
  cd ..  && \
  rm -rf ./build 
ENV Pangolin_DIR=${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin

# build sophus
WORKDIR /opt/slambook/3rdparty/Sophus
RUN set -x && \
	mkdir -p build && \
	cd build && \
	cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
	.. && \
  make -j${NUM_THREADS} && \
  make install && \
  cd ..  && \
  rm -rf ./build 
ENV Sophus_DIR=${CMAKE_INSTALL_PREFIX}/lib/cmake/Sophus

# OpenCV
ENV LC_ALL zh_CN.utf8
ENV LANG zh_CN.UTF-8 
#定义时区参数
ENV TZ=Asia/Shanghai
#设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' > /etc/timezone
RUN  DEBIAN_FRONTEND=noninteractivea set -x && apt-get update -y -qq && \
	apt-get install -y -qq  language-pack-zh-hans software-properties-common && \
	add-apt-repository "deb http://mirrors.aliyun.com/ubuntu/ xenial main universe" && \
	apt-get install -y -qq libgtk2.0-dev libvtk6-dev libjpeg-dev libtiff-dev \
	libjasper-dev libopenexr-dev libtbb-dev

ARG OPENCV_VERSION=3.1.0
WORKDIR /tmp
RUN set -x && \
  wget -q https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
  unzip -q ${OPENCV_VERSION}.zip 
ENV OPENCV_ICV_URL=https://ghproxy.com/\
https://raw.githubusercontent.com/opencv/opencv_3rdparty/ippicv/master_20151201/ippicv
ARG NUM_THREADS=8
RUN set -x && \
  rm -rf ${OPENCV_VERSION}.zip && \
  cd opencv-${OPENCV_VERSION} && \
  mkdir -p build && \
  cd build && \
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
    -DBUILD_DOCS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_OPENEXR=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_TESTS=OFF \
    -DENABLE_CXX11=ON \
    -DENABLE_FAST_MATH=ON \
    -DWITH_EIGEN=ON \
    -DWITH_FFMPEG=ON \
    -DWITH_OPENMP=ON \
    -DENABLE_PRECOMPILED_HEADERS=OFF \
    .. && \
  make -j${NUM_THREADS} && \
  make install && \
  cd /tmp && \
  rm -rf *
ENV OpenCV_DIR=${CMAKE_INSTALL_PREFIX}/share/OpenCV

ARG EXTERNAL_LIBRARY=/opt/slambook/3rdparty
WORKDIR ${EXTERNAL_LIBRARY}/g2o
RUN set -x && \
	apt-get install -y -qq qt5-qmake \
	qt5-default \
	libqglviewer-dev-qt5 \
	libsuitesparse-dev \
	libcxsparse3 \
	libcholmod3  && \
	mkdir -p build && \
  cd build && \
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_UNITTESTS=OFF \
#    -DG2O_USE_OPENGL=OFF \
#    -DG2O_USE_OPENMP=ON \
    -DG2O_BUILD_APPS=OFF \
    -DG2O_BUILD_EXAMPLES=OFF \
    -DG2O_BUILD_LINKED_APPS=OFF \
    .. && \
  make -j${NUM_THREADS} && \
  make install && \
  cd .. && \
  rm -rf ./build
ENV g2o_DIR=

WORKDIR ${EXTERNAL_LIBRARY}/ceres-solver
RUN set -x && \
	apt-get install -y -qq  libgoogle-glog-dev \
	liblapack-dev \
	libgflags-dev \
	libatlas-base-dev libsuitesparse-dev && mkdir -p build && \
	cd build && \
	cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
    .. && \
  make -j${NUM_THREADS} && \
  make install && \
  cd .. && \
  rm -rf ./build
ENV ceres_DIR=

# DBoW3
WORKDIR ${EXTERNAL_LIBRARY}/DBoW3
RUN set -x && \
	mkdir -p build && \
	cd build && \
	cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
    .. && \
    make -j${NUM_THREADS} && \
    make install && \
    cd .. && \
    rm -rf ./build

ENV DBoW3_DIR=

# pcl octomap octovis
RUN set -x && apt-get install -y -qq libpcl-dev pcl-tools \
	    liboctomap-dev octovis \
    libgtest-dev && \
	cd /usr/src/gtest && \
	mkdir build && \
	cd build && \
	cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
	.. && \
    make -j${NUM_THREADS} && \
    make install && \
    cd .. && \
    rm -rf ./build

COPY ./ /opt/slambook 
WORKDIR /opt/slambook
ENTRYPOINT ["/bin/bash"]
