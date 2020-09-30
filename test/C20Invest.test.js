const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { expectEvent, expectRevert, ether, BN, time } = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

const C20 = contract.fromArtifact('C20');
const C20Invest = contract.fromArtifact('C20Invest');
const C20InvestProxy = contract.fromArtifact('C20InvestProxy');
const C20Vesting = contract.fromArtifact('C20Vesting');
const ReentrancyGetTokens = contract.fromArtifact('ReentrancyGetTokens');
const ProxyAdmin = contract.fromArtifact('ProxyAdmin');

async function getBal (account) {
  return new BN(await web3.eth.getBalance(account));
}

describe('C20InvestProxy', function () {
  const [
    fundWallet,
    controlWallet,
    otherTokenHolders,
    user1,
    user2,
    user3,
    proxyAdminOwner,
    attacker,
  ] = accounts;

  let c20;
  let c20Vesting;
  let c20Invest;
  let c20InvestProxy;
  let proxyAdmin;

  before(async function () {
    c20 = await C20.new(controlWallet, 300000, 0, 7, { from: fundWallet, gas: 5000000 });
    c20Vesting = await C20Vesting.new(c20.address, 7, { from: fundWallet });
    await c20.setVestingContract(c20Vesting.address, { from: fundWallet });

    const fundWalletValueToSend = ether('30844.96');
    await c20.buy({ from: fundWallet, value: fundWalletValueToSend });

    c20.verifyParticipant(otherTokenHolders, { from: fundWallet });
    const otherTokenHoldersValueToSend = ether('104675.31');
    await c20.buy({ from: otherTokenHolders, value: otherTokenHoldersValueToSend });

    await time.advanceBlock();
    await c20.enableTrading({ from: fundWallet });

    proxyAdmin = await ProxyAdmin.new({ from: proxyAdminOwner });
    const c20InvestLogic = await C20Invest.new();
    const calldata =
      c20InvestLogic.contract.methods['initialize(address,address)'](fundWallet, c20.address).encodeABI();

    c20InvestProxy = await C20InvestProxy.new(c20InvestLogic.address, proxyAdmin.address, calldata);

    c20Invest = await C20Invest.at(c20InvestProxy.address);

    await c20.transfer(c20Invest.address, ether(new BN(9253487)), { from: fundWallet });
  });

   describe("Initializer", function(){
      it(
         "cannot be reinitialized",
         async function() {
            await expectRevert(
               c20Invest.initialize(fundWallet, c20.address),
               "Initializable: contract is already initialized"
            );
         }
      );
   })

  describe('Ownership', function () {
    it(
      'should have owner as fundWallet',
      async function () {
        const owners = await c20Invest.getOwner.call();
        expect(owners).to.be.equal(fundWallet);
      },
    );
  });

  describe('Sending Ether', function () {
    it(
      'does not allow amounts below minimum investment',
      async function () {
        await expectRevert(
          c20Invest.send(0.01e18, { from: user1 }),
          'C20Invest: ether received below minimum investment',
        );
      },
    );

    it(
      'should receive user\'s money, correctly record balance and request time and emits EtherDeposited',
      async function () {
        const receipt = await c20Invest.send(1e18, { from: user1 });
        const initC20InvestBalance = await getBal(c20Invest.address);

        expectEvent(
          receipt,
          'EtherDeposited',
          { sender: user1, amount: ether('1') },
        );

        const etherBalance = (await c20Invest.userBalances.call(user1)).toString();
        const requestTime = (await c20Invest.requestTime.call(user1)).toNumber();
        expect(initC20InvestBalance).to.be.eql(ether('1'));
        expect(etherBalance).to.be.equal('1000000000000000000');
        expect(requestTime).to.be.at.most((await time.latest()).toNumber());
        expect(requestTime).to.be.at.least((await time.latest()).toNumber() - 10);
      },
    );
  });

  describe('Getting Tokens', function () {
    it(
      'prevents withdrawal if price has not been updated',
      async function () {
        await expectRevert(
          c20Invest.getTokens({ from: user1 }),
          'C20Invest: price has not updated yet',
        );
      },
    );

    it(
      'prevents withdrawal if user has no balance',
      async function () {
        await expectRevert(
          c20Invest.getTokens({ from: user2 }),
          'C20Invest: user has no ether for conversion',
        );
      },
    );

    it(
      'allows withdrawal after price updated and emits TokensPurchased',
      async function () {
        const initialContractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());

        await c20.updatePrice(100000, { from: fundWallet });

        const receipt = await c20Invest.getTokens({ from: user1 });

        const userBalance = new BN((await c20.balanceOf.call(user1)).toString());
        const contractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());
        const expectedNumberTokens = new BN('100000000000000000000');

        expectEvent(
          receipt,
          'TokensPurchased',
          { sender: user1, amount: expectedNumberTokens },
        );

        expect(userBalance).to.be.eql(expectedNumberTokens);
        expect(contractBalance).to.be.eql(initialContractBalance.sub(expectedNumberTokens));
      },
    );

    it(
      'prevents second attempt at withdrawing tokens',
      async function () {
        await expectRevert(
          c20Invest.getTokens({ from: user1 }),
          'C20Invest: user has no ether for conversion',
        );
      },
    );

    it(
      'refunds when amount deposited exceeds available tokens' +
                ' and emits RefundGiven',
      async function () {
        const initialContractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());

        const currentPrice = await c20.currentPrice.call();

        const user3BalanceInit = await getBal(user3);

        const etherToSend = initialContractBalance
          .mul(currentPrice.denominator)
          .div(currentPrice.numerator)
          .add(new BN('1'));
        const txReceipt = await c20Invest.send(etherToSend, { from: user3 });

        await time.increase(1);
        await c20.updatePrice(100000, { from: fundWallet });

        const txReceipt2 = await c20Invest.getTokens({ from: user3 });

        expectEvent(
          txReceipt2,
          'RefundGiven',
          { sender: user3, amount: etherToSend },
        );

        const userBalance = new BN((await c20.balanceOf.call(user3)).toString());
        const contractBalance = new BN((await c20.balanceOf.call(c20Invest.address)).toString());

        const gasPrice = new BN(await web3.eth.getGasPrice());
        const gasUsed = new BN(txReceipt.receipt.gasUsed + txReceipt2.receipt.gasUsed);
        const expectedBalance = user3BalanceInit
          .sub(gasPrice.mul(gasUsed));

        const user3BalanceAfter = await getBal(user3);

        expect(userBalance).to.be.eql(new BN('0'));
        expect(contractBalance).to.be.eql(initialContractBalance);
        expect(user3BalanceAfter).to.be.eql(expectedBalance);
      },
    );
  });

  describe('Admin', function () {
  
    it(
      'does not allow non-owner to set minimum investment',
      async function () {
        await expectRevert(
          c20Invest.setMinInvestment(ether("0.2"), {from: user1}),
          'C20Invest: caller is not the owner',
        );
      },
    );
  
    it(
      'allows owner to set minimum investment',
      async function () {
         await c20Invest.setMinInvestment(ether("0.2"), {from: fundWallet});
         let minInvestment = await c20Invest.minInvestment.call();
         
         expect(minInvestment).to.be.bignumber.equal(ether("0.2"));
      },
    );
  
    it(
      'does not allow non-owner to withdraw ether from contract',
      async function () {
        await expectRevert(
          c20Invest.withdrawETHBalance(ether('1'), { from: user1 }),
          'C20Invest: caller is not the owner',
        );
      },
    );
    
    it(
      'allows owner to withdraw ether from contract and yields correct balance',
      async function () {
        const initFundWalletBalance = await getBal(fundWallet);

        const txReceipt = await c20Invest.withdrawETHBalance(ether('1'), { from: fundWallet });
        const gasPrice = new BN(await web3.eth.getGasPrice());
        const expectedBalance = initFundWalletBalance
          .sub(gasPrice.mul(new BN(txReceipt.receipt.gasUsed)))
          .add(ether('1'));
        const finalFundWalletBalance = await getBal(fundWallet);
        const finalC20InvestBalance = await getBal(c20Invest.address);

        expect(expectedBalance).to.be.eql(finalFundWalletBalance);
        expect(ether('0')).to.be.eql(finalC20InvestBalance);
      },
    );

    it(
      'does not allow withdrawing more than contract balance',
      async function () {
        await c20Invest.send(ether('1.5'), { from: user1 });
        const initC20InvestBalance = await getBal(c20Invest.address);

        await expectRevert(
          c20Invest.withdrawETHBalance(initC20InvestBalance.add(ether('2')), { from: fundWallet }),
          'C20Invest: amount greater than available balance',
        );

        await time.increase(1);
        await c20.updatePrice(100000, { from: fundWallet });
        await c20Invest.getTokens({ from: user1 });
      },
    );

    it(
      'does not allow withdrawing unconverted ether',
      async function () {
        const initC20InvestBalance = await getBal(c20Invest.address);
        await c20Invest.send(ether('1'), { from: user3 });

        await expectRevert(
          c20Invest.withdrawETHBalance(initC20InvestBalance.add(ether('1')), { from: fundWallet }),
          'C20Invest: amount greater than available balance',
        );
      },
    );

    it(
      'allows withdrawing everything but unconverted ether',
      async function () {
        const initC20InvestBalance = await getBal(c20Invest.address);
        const initFundWalletBalance = await getBal(fundWallet);

        const txReceipt = await c20Invest.withdrawETHBalance(ether('1.5'), { from: fundWallet });

        const gasPrice = new BN(await web3.eth.getGasPrice());
        const expectedBalance = initFundWalletBalance
          .sub(gasPrice.mul(new BN(txReceipt.receipt.gasUsed)))
          .add(ether('1.5'));
        const finalFundWalletBalance = await getBal(fundWallet);
        const finalC20InvestBalance = await getBal(c20Invest.address);

        expect(expectedBalance).to.be.eql(finalFundWalletBalance);
        expect(finalC20InvestBalance).to.be.eql(initC20InvestBalance.sub(ether('1.5')));
      },
    );
    
    it(
      'does not allow non-owner to use removeAllEther()',
      async function () {
        await expectRevert(
          c20Invest.removeAllEther({ from: user1 }),
          'C20Invest: caller is not the owner',
        );
      },
    );
    
    it(
      'allows removeAllEther() to withdraw everything including unconverted ether',
      async function () {
        const initC20InvestBalance = await getBal(c20Invest.address);
        const initFundWalletBalance = await getBal(fundWallet);

        const txReceipt = await c20Invest.removeAllEther({ from: fundWallet });

        const gasPrice = new BN(await web3.eth.getGasPrice());
        const expectedBalance = initFundWalletBalance
          .sub(gasPrice.mul(new BN(txReceipt.receipt.gasUsed)))
          .add(initC20InvestBalance);
        const finalFundWalletBalance = await getBal(fundWallet);
        const finalC20InvestBalance = await getBal(c20Invest.address);
        
        expect(expectedBalance).to.be.bignumber.equal(finalFundWalletBalance);
        expect(finalC20InvestBalance).to.be.bignumber.equal(new BN("0"));
      },
    );

    it(
      'does not transfer out remaining token balance to nonowner',
      async function () {
        await expectRevert(
          c20Invest.removeTokens({ from: user1 }),
          'C20Invest: caller is not the owner',
        );
      },
    );

    it(
      'transfers out remaining token balance',
      async function () {
        const initFundWalletTokenBalance = await c20.balanceOf.call(fundWallet);
        const initContractTokenBalance = await c20.balanceOf.call(c20Invest.address);
        await c20Invest.removeTokens({ from: fundWallet });
        const finalFundWalletTokenBalance = await c20.balanceOf.call(fundWallet);
        const finalContractTokenBalance = await c20.balanceOf.call(c20Invest.address);

        expect(finalFundWalletTokenBalance.toString())
          .to.be.eql(initFundWalletTokenBalance.add(initContractTokenBalance).toString());
        expect(finalContractTokenBalance.toString()).to.be.eql('0');
      },
    );
    
  });
  
  describe("Reentrancy", function(){
    it(
      'does not allow reentrancy in getTokens() for refund',
      async function(){
         await c20Invest.send(ether("10"), { from: user1 });
         let reentrancyGetTokens = await ReentrancyGetTokens.new(c20Invest.address);
         await reentrancyGetTokens.depositFunds({value: ether("1"), from: attacker});
         let initC20InvestBalance = await getBal(c20Invest.address);
         
         await time.increase(1);
         await c20.updatePrice(100000, { from: fundWallet });
         
         await expectRevert(
            reentrancyGetTokens.attackC20Invest({from: attacker}),
            "C20Invest: getTokens refund error"
         );
         
         let finalC20InvestBalance = await getBal(c20Invest.address);
         let finalAttackerBalance = await getBal(reentrancyGetTokens.address);
         
         expect(finalC20InvestBalance).to.be.bignumber.equal(ether("11"));
         expect(finalAttackerBalance).to.be.bignumber.equal(ether("0"))
        
      }
    );
  });
  
});
