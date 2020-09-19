Proxy Contracts
===============

The OpenZeppelin implementations in this section are an example of
the unstructured storage proxy pattern. More information can be found
on this pattern at the following two links:

1. `Proxy Patterns <https://blog.openzeppelin.com/proxy-patterns/>`_
2. `Proxy Upgrade Pattern <https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies>`_.


The gist of what you need to know when upgrading is that the storage
layout of the proxy should not change. This means that all existing
state variables must be declared in the order in which they were
declared in the original logic/implementation contract.

This has two implications.

- The first being that changes in code of inherited contracts may cause storage
  corruption since it is possible that new state variables will be declared
  (or even just have their order swapped around). This means that you should not update
  the contracts you inherit from.
- Secondly, the logic contract itself should not have any new state variables
  added before any previously declared state variables. Practically this means
  that you should only update the logic contract with features you need, after all
  previously written code (i.e. append changes only at the end of the source
  code). Updating features in inherited contracts should also be done at the
  end of the logic contract.


There is no danger with changing variables within functions or
changing/adding code within functions, as long as you declare
all needed state variables at the end of the logic contract.

.. toctree::
    initializable.rst
    proxy.rst
    upgradeableproxy.rst
    transparentupgradeableproxy.rst
    proxyadmin.rst