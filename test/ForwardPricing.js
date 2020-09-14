
const { contract, web3 } = require('@openzeppelin/test-environment');
const C20JSON = require('../build/contracts/C20.json');

module.exports = function forwardPrice(c20) {
    new web3.eth.Contract(C20JSON.abi, c20.address)
}