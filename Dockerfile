#################
#### BUILDER ####
#################
FROM resin/rpi-raspbian:stretch AS builder

# Create variables
ENV build_space /home/build

# Install the build tools
RUN apt-get update && \
    apt-get install -y \
        apt-utils \
        build-essential \
        autoconf \
        automake \
        libtool \
        curl \
        unzip \
        cmake \
        wget

##########################
#### PROTOBUF_BUILDER ####
##########################
FROM resin/rpi-raspbian:stretch AS protobuf_builder
COPY --from=builder / /

# Create variables
ENV build_space /home/build
ENV protobuf_version 3.6.0
ENV protobuf_url https://github.com/google/protobuf/releases/download/v${protobuf_version}/protobuf-cpp-${protobuf_version}.tar.gz

# Go into the build space
WORKDIR ${build_space}

# Download protobuf into the build space
RUN wget ${protobuf_url} && tar -xvzf *.tar.gz
WORKDIR ${build_space}/protobuf-${protobuf_version}

# Configure, build and install
RUN ./autogen.sh \
    && ./configure --disable-shared \
    && make -j \
    && make install

#########################
#### DJIOSDK_BUILDER ####
#########################
FROM resin/rpi-raspbian:stretch AS djiosdk_builder
COPY --from=builder / /

# Create variables
ENV build_space /home/build
ENV djiosdk_version 3.4.2
ENV djiosdk_url https://github.com/dji-sdk/Onboard-SDK/archive/${djiosdk_version}.tar.gz

# Go into the build space
WORKDIR ${build_space}

# Download the djiosdk into the build space
RUN wget ${djiosdk_url} && tar -xvzf *.tar.gz
WORKDIR ${build_space}/Onboard-SDK-${djiosdk_version}

# Make a build directory
RUN mkdir build

# Go into build directory
WORKDIR ${build_space}/Onboard-SDK-${djiosdk_version}/build

# Configure, build and install
RUN cmake .. -DCMAKE_BUILD_TYPE=Debug \
    && make -j \
    && make install

#######################
#### MUDUO_BUILDER ####
#######################
FROM resin/rpi-raspbian:stretch AS muduo_builder
COPY --from=builder / /
COPY --from=protobuf_builder /usr/local/ /usr/local/ 

# Create variables
ENV build_space /home/build
ENV muduo_version 1.1.0
ENV muduo_url https://github.com/chenshuo/muduo/archive/v${muduo_version}.tar.gz

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        zlib1g-dev \
        libcurl4-openssl-dev \
        libboost-all-dev

# Go into the build space
WORKDIR ${build_space}

# Download muduo into the build space
RUN wget ${muduo_url} && tar -xvzf *.tar.gz
WORKDIR ${build_space}/muduo-${muduo_version}

# Make a build directory
RUN mkdir build

# Go into build directory
WORKDIR ${build_space}/muduo-${muduo_version}/build

# Configure, build and install
RUN cmake .. -DCMAKE_BUILD_NO_EXAMPLES=1 \
    && make -j \
    && make install

#####################
#### DEVELOPMENT ####
#####################
FROM resin/rpi-raspbian:stretch AS development
COPY --from=builder / /
COPY --from=protobuf_builder /usr/local/ /usr/local/
COPY --from=djiosdk_builder /usr/local/ /usr/local/
COPY --from=muduo_builder /usr/local/ /usr/local/

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        zlib1g-dev \
        libcurl4-openssl-dev \
        libboost-all-dev

ENV build_space /home/build

# Go into the build space
WORKDIR ${build_space}

RUN mkdir tppi

COPY CMakeLists.txt ./tppi/
COPY server.cpp ./tppi/
COPY client.cpp ./tppi/

RUN mkdir tppi/build

WORKDIR ${build_space}/tppi/build

RUN cmake .. && make -j

#################
#### RELEASE ####
#################
FROM resin/rpi-raspbian:stretch AS release

ENV deployment_dir /home/deployment

RUN mkdir -p ${deployment_dir}

COPY --from=development /home/build/tppi/build/tppi_server ${deployment_dir}
COPY --from=development /home/build/tppi/build/tppi_client ${deployment_dir}