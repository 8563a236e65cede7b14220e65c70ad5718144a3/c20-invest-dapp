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

Unit Test Results
=================

Current run::

   > c20-invest-dapp@0.1.0 test /media/Database/Documents/Solidity/c20-invest-dapp
   > mocha --exit --recursive --ignore test/C20InvestProxy.test.js && mocha --exit test/C20InvestProxy.test.js
     C20Invest
       Ownership
         ✓ should have owner as fundWallet
       Sending Ether
         ✓ does not allow amounts below minimum investment (87ms)
         ✓ should receive user's money, correctly record balance and request time (106ms)
       Getting Tokens
         ✓ prevents withdrawal if price has not been updated (69ms)
         ✓ prevents withdrawal if user has no balance (63ms)
         ✓ allows withdrawal after price updated (220ms)
         ✓ prevents second attempt at withdrawing tokens (58ms)
         ✓ refunds when amount deposited exceeds available tokens and suspends contract (352ms)
       Suspendable Operations
         ✓ prevents buying while contract is suspended (48ms)
         ✓ does not resume if contract token balance is zero (79ms)
         ✓ successfully resumes contract from suspension (170ms)
       Admin
         ✓ does not allow non-owner to withdraw ether from contract (57ms)
         ✓ allows owner to withdraw ether from contract and yields correct balance (58ms)
         ✓ does not allow withdrawing more than contract balance (55ms)
         ✓ does not transfer out remaining token balance to nonowner (46ms)
         ✓ transfers out remaining token balance (163ms)

     Ownable
       Constructor
         ✓ initializes owner to msg.sender with empty array (92ms)
         ✓ initializes owner to given addresses with non-empty array (77ms)
       Check Ownership
         ✓ checks existing owner address found in _owners array (81ms)
         ✓ checks non-owner address not found in _owners array (87ms)
         ✓ finds correct indices of owners (96ms)
         ✓ returns -1 if address is not an owner (72ms)
       Add Owner
         ✓ adds a new owner (107ms)
         ✓ prevents adding owner that already exists (93ms)
         ✓ prevents non-owners from adding new owners (86ms)
       Remove Owner
         ✓ removes owner correctly (145ms)
         ✓ prevents non-owner from removing (85ms)
         ✓ prevents removal when only one owner (90ms)
         ✓ revokes ownership correctly (135ms)
       Transfer Ownership
         ✓ adds new owner and removes old (136ms)

     Initializable
       basic testing without inheritance
         before initialize
           ✓ initializer has not run
         after initialize
           ✓ initializer has run
           ✓ initializer does not run again
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
         ✓ changes proxy admin (53ms)
       #getProxyImplementation
         ✓ returns proxy implementation address
       #upgrade
         with unauthorized account
           ✓ fails to upgrade (40ms)
         with authorized account
           ✓ upgrades implementation (61ms)
       #upgradeAndCall
         with unauthorized account
           ✓ fails to upgrade (47ms)
         with authorized account
           with invalid callData
             ✓ fails to upgrade (49ms)
           with valid callData
             ✓ upgrades implementation (77ms)

     TransparentUpgradeableProxy
       ✓ cannot be initialized with a non-contract address (48ms)
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
             ✓ reverts (52ms)
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
             ✓ reverts (53ms)
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
             ✓ upgrades to the requested implementation (56ms)
             ✓ emits an event (42ms)
           when the given implementation is the zero address
             ✓ reverts (39ms)
         when the sender is not the admin
           ✓ reverts (42ms)
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
             ✓ reverts (48ms)
         with migrations
           when the sender is the admin
             when upgrading to V1
               ✓ upgrades to the requested version and emits an event
               ✓ calls the 'initialize' function and sends given value to the proxy
               when upgrading to V2
                 ✓ upgrades to the requested version and emits an event
                 ✓ calls the 'migrate' function and sends given value to the proxy (39ms)
                 when upgrading to V3
                   ✓ upgrades to the requested version and emits an event
                   ✓ calls the 'migrate' function and sends given value to the proxy (40ms)
           when the sender is not the admin
             ✓ reverts (72ms)
       changeAdmin
         when the new proposed admin is not the zero address
           when the sender is the admin
             ✓ assigns new proxy admin
             ✓ emits an event
           when the sender is not the admin
             ✓ reverts (45ms)
         when the new proposed admin is the zero address
           ✓ reverts (41ms)
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
         ✓ should remove function (219ms)
         ✓ should change function signature (212ms)
         ✓ should add fallback function (206ms)
         ✓ should remove fallback function (176ms)

     UpgradeableProxy
       ✓ cannot be initialized with a non-contract address (40ms)
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
             ✓ reverts (43ms)
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
             ✓ reverts (45ms)
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
         ✓ returns true for contract address (58ms)
       sendValue
         when sender contract has no funds
           ✓ sends 0 wei
           ✓ reverts when sending non-zero amounts
         when sender contract has funds
           ✓ sends 0 wei
           ✓ sends non-zero amounts
           ✓ sends the whole balance (45ms)
           ✓ reverts when sending more than the balance
           with contract recipient
             ✓ sends funds (76ms)
             ✓ reverts on recipient revert (68ms)
       functionCall
         with valid contract receiver
           ✓ calls the requested function (53ms)
           ✓ reverts when the called function reverts with no reason (42ms)
           ✓ reverts when the called function reverts, bubbling up the revert reason (43ms)
           ✓ reverts when the called function runs out of gas (1157ms)
           ✓ reverts when the called function throws (39ms)
           ✓ reverts when function does not exist (40ms)
         with non-contract receiver
           ✓ reverts when address is not a contract
       functionCallWithValue
         with zero value
           ✓ calls the requested function (48ms)
         with non-zero value
           ✓ reverts if insufficient sender balance (40ms)
           ✓ calls the requested function with existing value (82ms)
           ✓ calls the requested function with transaction funds (54ms)
           ✓ reverts when calling non-payable functions (62ms)

     Suspendable
       Constructor
         ✓ should successfully deploy contract
       Suspension functionality
         ✓ should suspend contract (56ms)
         ✓ should resume contract (84ms)
       Modifiers
         ✓ should not call an onlySuspended function while active
         ✓ should not call an onlyActive function while suspended (68ms)
       Events
         ✓ should emit Suspended event
         ✓ should emit Resumed event (67ms)


     165 passing (20s)
     1 pending



     C20InvestProxy
       Ownership
         ✓ should have owner as fundWallet
       Sending Ether
         ✓ does not allow amounts below minimum investment (96ms)
         ✓ should receive user's money, correctly record balance and request time (137ms)
       Getting Tokens
         ✓ prevents withdrawal if price has not been updated (76ms)
         ✓ prevents withdrawal if user has no balance (67ms)
         ✓ allows withdrawal after price updated (216ms)
         ✓ prevents second attempt at withdrawing tokens (66ms)
         ✓ refunds when amount deposited exceeds available tokens and suspends contract (356ms)
       Suspendable Operations
         ✓ prevents buying while contract is suspended (45ms)
         ✓ does not resume if contract token balance is zero (90ms)
         ✓ successfully resumes contract from suspension (168ms)
       Admin
         ✓ does not allow non-owner to withdraw ether from contract (53ms)
         ✓ allows owner to withdraw ether from contract and yields correct balance (63ms)
         ✓ does not allow withdrawing more than contract balance (63ms)
         ✓ does not transfer out remaining token balance to nonowner (54ms)
         ✓ transfers out remaining token balance (128ms)


     16 passing (3s)

