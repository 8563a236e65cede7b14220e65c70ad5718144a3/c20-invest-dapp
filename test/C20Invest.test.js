const { accounts, defaultSender, contract, web3 } = require("@openzeppelin/test-environment");
const { balance, constants, expectEvent, expectRevert, ether, BN, time } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const C20 = contract.fromArtifact("C20");
const C20Invest = contract.fromArtifact("C20Invest");
const C20Vesting = contract.fromArtifact("C20Vesting");

describe("C20Invest", function(){
        const [ fundWallet, controlWallet, dummyVesting, otherTokenHolders, user1, user2 ] = accounts;

        var c20;
        var c20Vesting;
        var c20Invest;

        before(async function(){
            var totalSupply = 40656081;
            var fundWalletSupply = 9253488;

            c20 = await C20.new(controlWallet, 300000, 0, 7, {from: fundWallet, gas: 5000000});
            //console.log("...C20 spawned...");
            c20Vesting = await C20Vesting.new(c20.address, 7, {from: fundWallet});
            //console.log("...C20 Vesting spawned...");
            await c20.setVestingContract(c20Vesting.address, {from: fundWallet});
            //console.log("...C20 Vesting Address set...");
            var vestingAddress = await c20.vestingContract.call();

            var currentPrice = await c20.currentPrice.call();

            //console.log((await c20.previousUpdateTime.call()).toString());
            //console.log("ether balance before ICO purchase (fundWallet): ", web3.utils.fromWei(await web3.eth.getBalance(fundWallet)));
            //console.log("ether balance before ICO purchase (otherTokenHolders): ", web3.utils.fromWei(await web3.eth.getBalance(otherTokenHolders)));
            //console.log("token balance (fundWallet): ", web3.utils.fromWei((await c20.balanceOf.call(fundWallet)).toString()));
            //console.log("token balance (otherTokenHolders): ", web3.utils.fromWei((await c20.balanceOf.call(otherTokenHolders)).toString()));

            var fundWalletValueToSend = ether("30844.96");
            await c20.buy({from: fundWallet, value: fundWalletValueToSend});


            c20.verifyParticipant(otherTokenHolders, {from: fundWallet});
            var otherTokenHoldersValueToSend = ether("104675.31");
            await c20.buy({from: otherTokenHolders, value: otherTokenHoldersValueToSend});


            //console.log("ether balance after ICO purchase (fundWallet): ", web3.utils.fromWei(await web3.eth.getBalance(fundWallet)));
            //console.log("ether balance after ICO purchase (otherTokenHolders): ", web3.utils.fromWei(await web3.eth.getBalance(otherTokenHolders)));
            //console.log("token balance (fundWallet): ", web3.utils.fromWei((await c20.balanceOf.call(fundWallet)).toString()));
            //console.log("token balance (otherTokenHolders): ", web3.utils.fromWei((await c20.balanceOf.call(otherTokenHolders)).toString()));
            await time.advanceBlock();
            //console.log((await time.latestBlock()).toNumber());

            //console.log("...C20 Invest spawned...");
            c20Invest = await C20Invest.new([fundWallet], c20.address);
            //console.log("c20 Invest Address: ", c20Invest.address);
            await c20.enableTrading({from: fundWallet});
            //console.log(await c20.tradeable.call());
            //console.log(await c20.halted.call());
            await c20.transfer(c20Invest.address, ether(new BN(9253487)), {from: fundWallet});
            //console.log("token balance (fundWallet): ", web3.utils.fromWei((await c20.balanceOf.call(fundWallet)).toString()));
            //console.log("token balance (c20Invest): ", web3.utils.fromWei((await c20.balanceOf.call(c20Invest.address)).toString()));

        });

        it(
            "should have owner as fundWallet",
            async function(){
                var owners = await c20Invest.getOwners.call();
                expect(owners).to.be.eql([fundWallet]);
            }
        );

        it(
            "should receive user's money, correctly record balance and request time",
            async function(){
                await c20Invest.send(1e18, {from: user1});
                var etherBalance = (await c20Invest.userBalances.call(user1)).toString();
                var requestTime = (await c20Invest.requestTime.call(user1)).toNumber();
                expect(etherBalance).to.be.equal("1000000000000000000")
                expect(requestTime).to.be.at.most((await time.latest()).toNumber());
                expect(requestTime).to.be.at.least((await time.latest()).toNumber() - 10);
            }
        );

        it(
            "prevents withdrawal if price has not been updated",
            async function(){
                await expectRevert(
                    c20Invest.getTokens({from: user1}),
                    "C20Invest: price has not updated yet"
                );
            }
        );

        it(
            "allows withdrawal after price updated",
            async function(){
                var currentPrice = await c20.currentPrice.call();
                var previousUpdateTime = await c20.previousUpdateTime.call();
                var initialContractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());

                await c20.updatePrice(100000, {from: fundWallet});

                await c20Invest.getTokens({from: user1});
                var userBalance = new BN((await c20.balanceOf.call(user1)).toString());
                var contractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());
                var expectedNumberTokens = new BN("100000000000000000000");

                expect(userBalance).to.be.eql(expectedNumberTokens);
                expect(contractBalance).to.be.eql(initialContractBalance.sub(expectedNumberTokens));

            }
        );

    }
);