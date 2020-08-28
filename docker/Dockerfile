# Take the newly created OS as a layer
FROM debian:latest

# Update the operating system and install
# python and node package managers for next
# layer's installations
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y python3.7 python3-pip \
    nodejs npm


# Install prerequisites and add ppa with key
RUN apt-get install -y software-properties-common && \
add-apt-repository -y ppa:ethereum/ethereum && \
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2A518C819BE37D2C2031944D1C52189C923F6CA9

# Create Ubuntu bionic sources list, update
# apt and install ethereum metapackage
RUN echo "deb http://ppa.launchpad.net/ethereum/ethereum/ubuntu bionic main" \
    > /etc/apt/sources.list.d/ethereum-bionic.list && \
echo "deb-src http://ppa.launchpad.net/ethereum/ethereum/ubuntu bionic main" \
    >> /etc/apt/sources.list.d/ethereum-bionic.list && \
apt-get update && \
apt-get install -y ethereum solc

# Create folder to store contract and
# tests code
RUN mkdir c20-invest
WORKDIR c20-invest

# Install development and testing dependencies
RUN npm init --yes npm install --save-dev \
    -g --unsafe-perm=true --allow-root    \
    ganache-cli                           \
    truffle                               \
    @openzeppelin/test-environment        \
    @openzeppelin/test-helpers            \
    mocha                                 \
    chai                                  \
    eslint                                \
    eslint-config-standard                \
    eslint-plugin-import                  \
    eslint-plugin-mocha-no-only           \
    eslint-plugin-node                    \
    eslint-plugin-promise                 \
    eslint-plugin-standard                \
    ethereumjs-util                       \
    ganache-core                          \
    solhint                               \
    solidity-coverage

# Install sphinx and solidity/javascript language
# domain plugin for automatic document generation
RUN pip install sphinx sphinxcontrib-soliditydomain sphinx-js