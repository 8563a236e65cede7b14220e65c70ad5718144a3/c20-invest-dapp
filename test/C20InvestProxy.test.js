const { accounts, defaultSender, contract, web3 } = require("@openzeppelin/test-environment");
const { balance, constants, expectEvent, expectRevert, ether, BN, time } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const C20 = contract.fromArtifact("C20");
const C20Invest = contract.fromArtifact("C20Invest");
const C20Vesting = contract.fromArtifact("C20Vesting");


describe("C20InvestProxy", function(){
        const [ fundWallet, controlWallet, dummyVesting, otherTokenHolders, user1, user2, proxyAdminAddress, proxyAdminOwner] = accounts;

        var c20;
        var c20Vesting;
        var c20Invest;

        const createProxy = async function (logic, admin, initData, opts) {
            return TransparentUpgradeableProxy.new(logic, admin, initData, opts);
        };

        before(async function(){
            var totalSupply = 40656081;
            var fundWalletSupply = 9253488;

            c20 = await C20.new(controlWallet, 300000, 0, 7, {from: fundWallet, gas: 5000000});
            c20Vesting = await C20Vesting.new(c20.address, 7, {from: fundWallet});
            await c20.setVestingContract(c20Vesting.address, {from: fundWallet});
            var vestingAddress = await c20.vestingContract.call();

            var currentPrice = await c20.currentPrice.call();

            var fundWalletValueToSend = ether("30844.96");
            await c20.buy({from: fundWallet, value: fundWalletValueToSend});


            c20.verifyParticipant(otherTokenHolders, {from: fundWallet});
            var otherTokenHoldersValueToSend = ether("104675.31");
            await c20.buy({from: otherTokenHolders, value: otherTokenHoldersValueToSend});

            await time.advanceBlock();
            c20Invest = await C20Invest.new([fundWallet], c20.address);
            await c20.enableTrading({from: fundWallet});
            await c20.transfer(c20Invest.address, ether(new BN(9253487)), {from: fundWallet});
        });


    }
);