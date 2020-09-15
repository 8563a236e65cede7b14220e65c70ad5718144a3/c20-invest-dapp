const { spawn } = require('child_process');
const { accounts, defaultSender, contract, web3, provider } = require("@openzeppelin/test-environment");
const { balance, constants, expectEvent, expectRevert, ether, BN, time } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const C20 = contract.fromArtifact("C20");
const C20JSON = require('../build/contracts/C20.json');
const C20Invest = contract.fromArtifact("C20Invest");
const C20Vesting = contract.fromArtifact("C20Vesting");

async function getBal(account) {
    return new BN(await web3.eth.getBalance(account))
}

describe("C20Invest", function(){
        const [ fundWallet, controlWallet, dummyVesting, otherTokenHolders, oracleAddress, user1, user2, user3] = accounts;

        var c20;
        var c20Vesting;
        var c20Invest;
        var web3socket;

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
            c20Invest = await C20Invest.new([fundWallet], c20.address);

            await c20.enableTrading({from: fundWallet});
            await c20.transfer(c20Invest.address, ether(new BN(9253487)), {from: fundWallet});
        });

        it(
            "should have owner as fundWallet",
            async function(){
                var owners = await c20Invest.getOwners.call();
                expect(owners).to.be.eql([fundWallet]);
            }
        );

        it(
            "does not allow amounts below minimum investment",
            async function(){
                await expectRevert(
                    c20Invest.send(0.01e18, {from: user1}),
                    "C20Invest: ether received below minimum investment"
                )

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
            "prevents withdrawal if user has no balance",
            async function(){
                await expectRevert(
                    c20Invest.getTokens({from: user2}),
                    "C20Invest: user has no ether for conversion"
                );
            }
        );

        it(
            "allows withdrawal after price updated",
            async function(){
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

        it(
            "prevents second attempt at withdrawing tokens",
            async function(){
                await expectRevert(
                    c20Invest.getTokens({from: user1}),
                    "C20Invest: user has no ether for conversion"
                );
            }
        );

        it(
            "refunds when amount deposited exceeds available tokens and suspends contract",
            async function(){

                var previousUpdateTime = await c20.previousUpdateTime.call();
                var initialContractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());

                var currentPrice = await c20.currentPrice.call()

                var user3BalanceInit = await getBal(user3);

                var etherToSend = initialContractBalance
                                    .mul(currentPrice.denominator)
                                    .div(currentPrice.numerator)
                                    .add(new BN("1"));
                var txReceipt = await c20Invest.send(etherToSend, {from: user3});


                await time.increase(1);
                await c20.updatePrice(100000, {from: fundWallet});

                var txReceipt2 = await c20Invest.getTokens({from: user3});

                var userBalance = new BN((await c20.balanceOf.call(user3)).toString());
                var contractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());

                var gasPrice = new BN(await web3.eth.getGasPrice());
                var gasUsed = new BN(txReceipt.receipt.gasUsed + txReceipt2.receipt.gasUsed);
                var expectedBalance = user3BalanceInit.sub(etherToSend)
                                        .sub(gasPrice.mul(gasUsed))
                                        .add(new BN("1"));

                //console.log([initialContractBalance.toString(), contractBalance.toString(), userBalance.toString()]);
                //console.log(await web3.eth.getBalance(user3))
                var user3BalanceAfter = await getBal(user3);
                var suspended = await c20Invest.isSuspended.call();

                expect(userBalance).to.be.eql(initialContractBalance);
                expect(contractBalance).to.be.eql(new BN("0"));
                expect(user3BalanceAfter).to.be.eql(expectedBalance);
                expect(suspended).to.be.equal(true);
            }
        );




    }
);