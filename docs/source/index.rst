.. C20 Invest Dapp documentation master file, created by
   sphinx-quickstart on Thu Sep  3 20:05:51 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to C20 Invest Dapp's documentation!
===========================================

Overview
--------

The repository aims to support the resale of redeemed :sol:contract:`C20` tokens
through a newly deployed smart contract.

Setup
-----

Requirements:

- NodeJS >= V12
- NPM
- Docker

It is recommended you use the ready-made docker environment. All commands in
the sections that follow should preferably run inside the container. To set
this up run the following code on the host machine::

    npm run docker_setup
    npm run docker_interactive

Linting and Formatting
----------------------

To check for code problems::

    npm run lint:js           # JavaScript
    npm run lint:sol          # Solidity
    npm run lint:slither      # Solidity Static Analyzer
    npm run lint              # Run all

Testing
-------

Run all tests::

    npm test

This will run the tests in two batches. The first batch excludes
C20InvestProxy.test.js and the second batch only includes it. This
is because the blockchain does not seem to reset between testing
:sol:contract:`C20Invest` and :sol:contract:`C20InvestProxy`.
This causes :sol:contract:`C20InvestProxy` to error
out if run in the same session as :sol:contract:`C20Invest`. Thus this single test
is run in isolation.

To run tests in a specific file::

    npx mocha --exit [path/to/file]

Documentation
-------------

To compile the docs run::

    npm run docs         # compile docs

They will be located inside the run directory within the root
project directory under docs/build/html/index.html

Deployment
----------

[TODO]

Quick Usage
-----------

Once inside the container, run::

    npx truffle compile  # compile contracts
    npm test             # run tests
    npm run docs         # compile docs

To save the state of your work on the
host machine, run::

    npm run save

This saves the work within the root project directory on the host machine, in a folder called run.

Design Requirements
-------------------

1. Forward Pricing
    The conversion price for tokens will be taken as the price at
    the next price update event, following the user's deposit.
2. Upgradeable
    The contract must implement the proxy pattern in order to support
    future updates and/or bug fixes.


Brief Section Contents
----------------------

The :ref:`Main` section contains the :sol:contract:`C20Invest` contract and its proxy. The
:sol:contract:`C20Invest` contract there is not the one that will eventually be deployed.
See :sol:contract:`C20InvestInitializable` for the actual contract that will be deployed.

The :ref:`Initializable Contracts` versions are necessary due to the way proxying functions
works. In essence, constructors are never called by a proxy since they
are not stored in the deployed contract's code. See
https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#the-constructor-caveat
for more information.

The :ref:`C20 Base Contracts` section contains the contracts that were deployed
as the original :sol:contract:`C20` contract, updated to Solidity version 0.7.0 syntax and
are purely for testing purposes. These must not be deployed.

The :ref:`Proxy Contracts` section contains the
`OpenZeppelin proxy contract implementations <https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/proxy>`_,
again updated to version 0.7.0 syntax. The :sol:contract:`TransparentUpgradeableProxy`
forms the base class for the :sol:contract:`C20InvestProxy`. Please see the section
for more information on the unstructured storage proxy pattern that is
implemented with the OpenZeppelin contracts and safety issues with
regards to upgrade paths.

The :ref:`Access` section contains a custom :sol:contract:`Ownable` contract that takes a
slightly different approach to the OpenZeppelin
`Ownable <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol>`_
contract but has the same results overall with only slight modification to the
constructor of contracts that inherit from it.

The :ref:`Math` section contains a newer version of the
`SafeMath <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol>`_
library than the version in :sol:contract:`SafeMath` and is accompanied
by a syntax change.

The :ref:`Utils` section contains a custom :sol:contract:`Suspendable` contract which has
a similar function to the OpenZeppelin
`Pausable <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Pausable.sol>`_
contract and an :sol:lib:`Address` library from OpenZeppelin that contains some helper functions.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   main_index.rst
   c20_base.rst
   initializable_index.rst
   proxy_index.rst
   access_index.rst
   math_index.rst
   utils_index.rst

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
