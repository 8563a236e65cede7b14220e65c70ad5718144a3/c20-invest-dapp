
const { contract, web3 } = require('@openzeppelin/test-environment');
const C20JSON = require('../build/contracts/C20.json');
const C20InvestJSON = require('../build/contracts/C20Invest.json');

module.exports = function forwardPrice(c20, c20Invest, oracleAddress) {
    var oracle = new web3.eth.Contract(C20JSON.abi, c20.address);
    oracle.oracleAddress = oracleAddress;
    oracle.c20Invest = new web3.eth.Contract(C20InvestJSON.abi, c20Invest.address);
    oracle.getPriceUpdate = async function() {
        var updates;
        updates = await this.getPastEvents("PriceUpdate");
        if(updates.length !== 0){
            await this.c20Invest.methods.priceUpdate().send({from: this.oracleAddress});
        }
    }

    return oracle;
}