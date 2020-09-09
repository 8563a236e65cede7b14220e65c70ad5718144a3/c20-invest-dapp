#!/usr/bin/env bash

# Change fallback and receive functions to a signature
# the sphinx solidity domain plugin can understand
(
  cd contracts
  sed -i -r "s/^(\s*)receive/\1function receive/g" $(find . -regex ".*\.sol$")
  sed -i -r "s/^(\s*)fallback/\1function fallback/g" $(find . -regex ".*\.sol$")
)

# Make the documentation
(
  cd docs
  make clean
  make html
)
  
# Reset fallback and receive functions to original
# code
(
  cd contracts
  sed -i -r "s/^(\s*)function receive/\1receive/g" $(find . -regex ".*\.sol$")
  sed -i -r "s/^(\s*)function fallback/\1fallback/g" $(find . -regex ".*\.sol$")
)