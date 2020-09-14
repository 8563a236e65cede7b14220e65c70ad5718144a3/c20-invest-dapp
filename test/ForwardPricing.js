
const { contract, web3 } = require('@openzeppelin/test-environment');
const C20JSON = require('../build/contracts/C20.json');

module.exports = function forwardPrice(c20) {
    var oracle = new web3.eth.Contract(C20JSON.abi, c20.address);
    oracle.getPriceUpdate = async function() {
        console.log((await this.getPastEvents("PriceUpdate")))
    }

    return oracle;
}