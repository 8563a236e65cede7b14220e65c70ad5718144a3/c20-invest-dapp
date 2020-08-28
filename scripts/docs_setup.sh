#!/usr/bin/env bash

# Install sphinx and solidity/javascript language
# domain plugin for automatic document generation
pip install sphinx sphinxcontrib-soliditydomain sphinx-js

# Make document directory and initialize sphinx
mkdir docs
(
  cd docs
  sphinx-quickstart
)

