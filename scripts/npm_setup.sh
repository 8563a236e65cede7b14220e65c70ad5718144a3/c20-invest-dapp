#!/usr/bin/env bash

# Initialize npm
npm init --yes

# Install development dependencies
npm install --save-dev ganache-cli        \
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
    solidity-coverage                     \
    jsdoc                                 \
    ethereumjs-util

