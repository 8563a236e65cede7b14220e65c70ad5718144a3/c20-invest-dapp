C20-Invest-Dapp
===============

Usage
-----
Run the following code

    npm run docker_setup
    npm run docker_interactive

Once inside the container, run

    npx truffle compile  # compile contracts
    npm test             # run tests
    npm run docs         # compile docs

To save the state of your work on the
host machine, run

    npm run save

Afterwards, look in the run directory of the host
machine and you can access the docs, coverage reports,
build artifacts etc. on the docker host.

Docs can be found in run/docs/build/html/index.html
    