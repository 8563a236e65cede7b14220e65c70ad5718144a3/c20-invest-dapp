.. C20 Invest Dapp documentation master file, created by
   sphinx-quickstart on Thu Sep  3 20:05:51 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to C20 Invest Dapp's documentation!
===========================================

Overview
--------

The repository aims to support the resale of redeemed C20 tokens
through a newly deployed smart contract.

Requirements
------------

1. Forward Pricing
    The conversion price for tokens will be taken as the price at
    the next price update event, following the user's deposit.
2. Upgradeable
    The contract must implement the proxy pattern in order to support
    future updates and/or bug fixes.

Usage
-----
Run the following code::

    npm run docker_setup
    npm run docker_interactive

Once inside the container, run::

    npx truffle compile  # compile contracts
    npm test             # run tests
    npm run docs         # compile docs

To save the state of your work on the
host machine, run::

    npm run save

Afterwards, look in the run directory of the host
machine and you can access the docs, coverage reports,
build artifacts etc. on the docker host.

Docs can be found in run/docs/build/html/index.html

Brief Section Contents
----------------------

The *Main* section contains the C20Invest contract and its proxy. The
C20Invest contract there is not the one that will eventually be deployed.
See C20InvestInitializable for the actual contract that will be deployed.

The *Initializable* versions are necessary due to the way proxying functions
works. In essence, constructors are never called by a proxy since they
are not stored in the deployed contract's code. See
https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#the-constructor-caveat
for more information.

The *C20 Base Contracts* section contains the contracts that were deployed
as the original C20 contract, updated to Solidity version 0.7.0 syntax and
are purely for testing purposes. These must not be deployed.

The *Proxy* section contains the OpenZeppelin proxy contract implementations,
again updated to version 0.7.0 syntax. The TransparentUpgradeableProxy
forms the base class for the C20InvestProxy. Please see the section
for more information on the unstructured storage proxy pattern that is
implemented with the OpenZeppelin contracts and safety issues with
regards to upgrade paths.

The *Access* section contains a custom Ownable contract that takes a
slightly different approach to the OpenZeppelin Ownable contract but
has the same results overall with only slight modification to the
constructor of contracts that inherit from it.

The *Math* section contains a newer version of the SafeMath library
than the version in "C20 Base Contracts/SafeMath" and is accompanied
by a syntax change.

The *Utils* section contains a custom Suspendable contract which has
a similar function to the OpenZeppelin Pausable contract and an Address
library from OpenZeppelin that contains some helper functions.

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
