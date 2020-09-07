const { accounts, defaultSender, contract, web3 } = require("@openzeppelin/test-environment");
const { balance, constants, expectEvent, expectRevert, ether, BN, time } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const C20 = contract.fromArtifact("C20");
const C20Invest = contract.fromArtifact("C20Invest");
const C20Vesting = contract.fromArtifact("C20Vesting");

describe("C20Invest", function(){
        const [ fundWallet, controlWallet, dummyVesting, otherTokenHolders, user1, user2 ] = accounts;

        beforeEach(async function(){
            var totalSupply = 40656081;
            var fundWalletSupply = 9253488;

            var c20 = await C20.new(controlWallet, 300000, 0, 7, {from: fundWallet, gas: 5000000});
            var c20Vesting = await C20Vesting.new(c20.address, 7, {from: fundWallet});
            await c20.setVestingContract(c20Vesting.address, {from: fundWallet});
            var vestingAddress = await c20.vestingContract.call();

            var currentPrice = await c20.currentPrice.call();

            //console.log("ether balance (fundWallet): ", web3.utils.fromWei(await web3.eth.getBalance(fundWallet)));
            //console.log("ether balance (otherTokenHolders): ", web3.utils.fromWei(await web3.eth.getBalance(otherTokenHolders)));

            var fundWalletValueToSend = ether("30844.96");
            await c20.buy({from: fundWallet, value: fundWalletValueToSend});


            c20.verifyParticipant(otherTokenHolders, {from: fundWallet});
            var otherTokenHoldersValueToSend = ether("104675.31");
            await c20.buy({from: otherTokenHolders, value: otherTokenHoldersValueToSend});


            //console.log("ether balance (fundWallet): ", web3.utils.fromWei(await web3.eth.getBalance(fundWallet)));
            //console.log("ether balance (otherTokenHolders): ", web3.utils.fromWei(await web3.eth.getBalance(otherTokenHolders)));
            //console.log("token balance (fundWallet): ", web3.utils.fromWei((await c20.balanceOf.call(fundWallet)).toString()));
            //console.log("token balance (otherTokenHolders): ", web3.utils.fromWei((await c20.balanceOf.call(otherTokenHolders)).toString()));
            await time.advanceBlock();
            //console.log((await time.latestBlock()).toNumber());

            var c20Invest = await C20Invest.new([fundWallet], c20.address);
            //console.log("c20 Invest Address: ", c20Invest.address);

        });

        it("should spawn C20Invest contract", async function(){

        });
    }
);