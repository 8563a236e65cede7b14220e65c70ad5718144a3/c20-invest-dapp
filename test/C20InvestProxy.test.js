const { accounts, defaultSender, contract, web3 } = require("@openzeppelin/test-environment");
const { balance, constants, expectEvent, expectRevert, ether, BN, time } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const C20 = contract.fromArtifact("C20");
const C20Invest = contract.fromArtifact("C20InvestInitializable");
const C20InvestProxy = contract.fromArtifact("C20InvestProxy");
const C20Vesting = contract.fromArtifact("C20Vesting");
const ProxyAdmin = contract.fromArtifact("ProxyAdmin");
const TransparentUpgradeableProxy = contract.fromArtifact('TransparentUpgradeableProxy');


describe("C20InvestProxy", function(){
        const [ fundWallet, controlWallet, dummyVesting, otherTokenHolders, user1, user2, proxyAdminOwner] = accounts;

        var c20;
        var c20Vesting;
        var c20Invest;
        var c20InvestProxy;
        var proxyAdmin;

        const createProxy = async function (logic, admin, initData, opts) {
            return TransparentUpgradeableProxy.new(logic, admin, initData, opts);
        };

        before(async function(){
            var totalSupply = 40656081;
            var fundWalletSupply = 9253488;

            c20 = await C20.new(controlWallet, 300000, 0, 7, {from: fundWallet, gas: 5000000});
            c20Vesting = await C20Vesting.new(c20.address, 7, {from: fundWallet});
            await c20.setVestingContract(c20Vesting.address, {from: fundWallet});

            var fundWalletValueToSend = ether("30844.96");
            await c20.buy({from: fundWallet, value: fundWalletValueToSend});

            c20.verifyParticipant(otherTokenHolders, {from: fundWallet});
            var otherTokenHoldersValueToSend = ether("104675.31");
            await c20.buy({from: otherTokenHolders, value: otherTokenHoldersValueToSend});

            await time.advanceBlock();
            await c20.enableTrading({from: fundWallet});

            proxyAdmin = await ProxyAdmin.new([], { from: proxyAdminOwner });
            c20Invest = await C20Invest.new();
            const calldata = c20Invest.contract.methods['initialize(address[],address)']([fundWallet], c20.address).encodeABI();

            c20InvestProxy = await C20InvestProxy.new(c20Invest.address, proxyAdmin.address, calldata);

            var caller = await C20Invest.at(c20InvestProxy.address);
            caller = await caller.methods;
            var owners = await caller["getOwners()"].call();
            console.log(owners);
            //console.log(await c20InvestProxy.send({ data: callGetOwners.toNumber() }));
            console.log(fundWallet);
            //await c20.transfer(c20Invest.address, ether(new BN(9253487)), {from: fundWallet});




        });

        it("empty test", async function(){

        });


    }
);