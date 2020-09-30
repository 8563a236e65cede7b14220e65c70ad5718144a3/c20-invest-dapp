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

Run::

    npm run setup

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


To run tests in a specific file::

    npx mocha --exit [path/to/file]

Documentation
-------------

To compile the docs run::

    npm run docs         # compile docs


Deployment
----------

Deployment to the local development blockchain is fairly easy::

    npx truffle compile  # compile contracts
    npx truffle develop  # enter development environment
    migrate --reset      # deploy contracts, resetting network artifacts

To deploy to Rinkeby::

    [TODO]

Quick Usage
-----------

Once setup, run::

    npx truffle compile  # compile contracts
    npm test             # run tests
    npm run docs         # compile docs


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
:sol:contract:`C20Invest` contract there is the logic contract that will sit behind the proxy.


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


The :ref:`Math` section contains a newer version of the
`SafeMath <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol>`_
library than the version in :sol:contract:`SafeMath` and is accompanied
by a syntax change.

The :ref:`Utils` section contains an :sol:lib:`Address` library
from OpenZeppelin that contains some helper functions.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   main_index.rst
   c20_base.rst
   proxy_index.rst
   math_index.rst
   utils_index.rst

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

Unit Test Results
=================

Current run::

   
   > c20-invest-dapp@0.1.0 test /media/Database/Documents/Solidity/c20-invest-dapp
   > mocha --exit --recursive
     C20InvestProxy
       Initializer
         ✓ cannot be reinitialized (88ms)
       Ownership
         ✓ should have owner as fundWallet
       Sending Ether
         ✓ does not allow amounts below minimum investment (57ms)
         ✓ should receive user's money, correctly record balance and request time and emits EtherDeposited (129ms)
       Getting Tokens
         ✓ prevents withdrawal if price has not been updated (70ms)
         ✓ prevents withdrawal if user has no balance (69ms)
         ✓ allows withdrawal after price updated and emits TokensPurchased (201ms)
         ✓ prevents second attempt at withdrawing tokens (64ms)
         ✓ refunds when amount deposited exceeds available tokens and emits RefundGiven (288ms)
       Admin
         ✓ does not allow non-owner to set minimum investment (54ms)
         ✓ allows owner to set minimum investment (64ms)
         ✓ does not allow non-owner to withdraw ether from contract (48ms)
         ✓ allows owner to withdraw ether from contract and yields correct balance (58ms)
         ✓ does not allow withdrawing more than contract balance (254ms)
         ✓ does not allow withdrawing unconverted ether (101ms)
         ✓ allows withdrawing everything but unconverted ether (63ms)
         ✓ does not allow non-owner to use removeAllEther() (46ms)
         ✓ allows removeAllEther() to withdraw everything including unconverted ether (47ms)
         ✓ does not transfer out remaining token balance to nonowner (42ms)
         ✓ transfers out remaining token balance (133ms)
       Reentrancy
         ✓ does not allow reentrancy in getTokens() for refund (295ms)
   
     SafeMath
       add
         ✓ adds correctly
         ✓ reverts on addition overflow (43ms)
       sub
         ✓ subtracts correctly
         ✓ reverts if subtraction result would be negative
       mul
         ✓ multiplies correctly
         ✓ multiplies by zero correctly (40ms)
         ✓ reverts on multiplication overflow (44ms)
       div
         ✓ divides correctly
         ✓ divides zero correctly
         ✓ returns complete number result on non-even division
         ✓ reverts on division by zero
       mod
         ✓ reverts with a 0 divisor
         modulos correctly
           ✓ when the dividend is smaller than the divisor
           ✓ when the dividend is equal to the divisor
           ✓ when the dividend is larger than the divisor
           ✓ when the dividend is a multiple of the divisor
   
     Initializable
       basic testing without inheritance
         before initialize
           ✓ initializer has not run
         after initialize
           ✓ initializer has run
           ✓ initializer does not run again (45ms)
         after nested initialize
           ✓ initializer has run
       complex testing with inheritance
         ✓ initializes human
         ✓ initializes mother
         ✓ initializes gramps
         ✓ initializes father
         ✓ initializes child
   
     ProxyAdmin
       ✓ has an owner
       #getProxyAdmin
         ✓ returns proxyAdmin as admin of the proxy
       #changeProxyAdmin
         ✓ fails to change proxy admin if its not the proxy owner
         ✓ changes proxy admin (55ms)
       #getProxyImplementation
         ✓ returns proxy implementation address
       #upgrade
         with unauthorized account
           ✓ fails to upgrade (41ms)
         with authorized account
           ✓ upgrades implementation (69ms)
       #upgradeAndCall
         with unauthorized account
           ✓ fails to upgrade (42ms)
         with authorized account
           with invalid callData
             ✓ fails to upgrade (51ms)
           with valid callData
             ✓ upgrades implementation (64ms)
   
     TransparentUpgradeableProxy
       ✓ cannot be initialized with a non-contract address (45ms)
       without initialization
         when not sending balance
           ✓ sets the implementation address
           ✓ initializes the proxy
           ✓ has expected balance
         when sending some balance
           ✓ sets the implementation address
           ✓ initializes the proxy
           ✓ has expected balance
       initialization without parameters
         non payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ reverts (49ms)
         payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
       initialization with parameters
         non payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ reverts (46ms)
         payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
       implementation
         ✓ returns the current implementation address
         ✓ delegates to the implementation
       upgradeTo
         when the sender is the admin
           when the given implementation is different from the current one
             ✓ upgrades to the requested implementation (62ms)
             ✓ emits an event (42ms)
           when the given implementation is the zero address
             ✓ reverts (41ms)
         when the sender is not the admin
           ✓ reverts (39ms)
       upgradeToAndCall
         without migrations
           when the call does not fail
             when the sender is the admin
               ✓ upgrades to the requested implementation
               ✓ emits an event
               ✓ calls the initializer function
               ✓ sends given value to the proxy
               - uses the storage of the proxy
             when the sender is not the admin
               ✓ reverts (40ms)
           when the call does fail
             ✓ reverts (44ms)
         with migrations
           when the sender is the admin
             when upgrading to V1
               ✓ upgrades to the requested version and emits an event
               ✓ calls the 'initialize' function and sends given value to the proxy
               when upgrading to V2
                 ✓ upgrades to the requested version and emits an event
                 ✓ calls the 'migrate' function and sends given value to the proxy (38ms)
                 when upgrading to V3
                   ✓ upgrades to the requested version and emits an event
                   ✓ calls the 'migrate' function and sends given value to the proxy (42ms)
           when the sender is not the admin
             ✓ reverts (74ms)
       changeAdmin
         when the new proposed admin is not the zero address
           when the sender is the admin
             ✓ assigns new proxy admin
             ✓ emits an event
           when the sender is not the admin
             ✓ reverts (43ms)
         when the new proposed admin is the zero address
           ✓ reverts
       storage
         ✓ should store the implementation address in specified location
         ✓ should store the admin proxy in specified location
       transparent proxy
         ✓ proxy admin cannot call delegated functions
         when function names clash
           ✓ when sender is proxy admin should run the proxy function
           ✓ when sender is other should delegate to implementation
       regression
         ✓ should add new function (208ms)
         ✓ should remove function (227ms)
         ✓ should change function signature (193ms)
         ✓ should add fallback function (180ms)
         ✓ should remove fallback function (190ms)
   
     UpgradeableProxy
       ✓ cannot be initialized with a non-contract address
       without initialization
         when not sending balance
           ✓ sets the implementation address
           ✓ initializes the proxy
           ✓ has expected balance
         when sending some balance
           ✓ sets the implementation address
           ✓ initializes the proxy
           ✓ has expected balance
       initialization without parameters
         non payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ reverts (57ms)
         payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
       initialization with parameters
         non payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ reverts (46ms)
         payable
           when not sending balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
           when sending some balance
             ✓ sets the implementation address
             ✓ initializes the proxy
             ✓ has expected balance
   
     Address
       isContract
         ✓ returns false for account address
         ✓ returns true for contract address (56ms)
       sendValue
         when sender contract has no funds
           ✓ sends 0 wei
           ✓ reverts when sending non-zero amounts
         when sender contract has funds
           ✓ sends 0 wei (39ms)
           ✓ sends non-zero amounts
           ✓ sends the whole balance (40ms)
           ✓ reverts when sending more than the balance (48ms)
           with contract recipient
             ✓ sends funds (80ms)
             ✓ reverts on recipient revert (76ms)
       functionCall
         with valid contract receiver
           ✓ calls the requested function (51ms)
           ✓ reverts when the called function reverts with no reason (42ms)
           ✓ reverts when the called function reverts, bubbling up the revert reason (40ms)
           ✓ reverts when the called function runs out of gas (1186ms)
           ✓ reverts when the called function throws
           ✓ reverts when function does not exist (40ms)
         with non-contract receiver
           ✓ reverts when address is not a contract
       functionCallWithValue
         with zero value
           ✓ calls the requested function (49ms)
         with non-zero value
           ✓ reverts if insufficient sender balance
           ✓ calls the requested function with existing value (86ms)
           ✓ calls the requested function with transaction funds (56ms)
           ✓ reverts when calling non-payable functions (63ms)
   
   
     165 passing (20s)
     1 pending
