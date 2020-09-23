const C20 = artifacts.require('C20');
const C20Invest = artifacts.require('C20InvestInitializable');
const C20InvestProxy = artifacts.require('C20InvestProxy');
const C20Vesting = artifacts.require('C20Vesting');
const ProxyAdmin = artifacts.require('ProxyAdmin');

module.exports = async function (deployer, network, accounts) {
  const [
    fundWallet,
    controlWallet,
    proxyAdminOwner,
  ] = accounts;

  await deployer.deploy(C20, controlWallet, 300000, 0, 7, { from: fundWallet, gas: 5000000 });
  const c20 = await C20.deployed();
  await deployer.deploy(C20Vesting, c20.address, 7, { from: fundWallet });
  await deployer.deploy(ProxyAdmin, [], { from: proxyAdminOwner });
  let proxyAdmin = await ProxyAdmin.deployed();
  await deployer.deploy(C20Invest);

  const c20InvestLogic = await C20Invest.deployed();
  const calldata =
    c20InvestLogic.contract.methods['initialize(address[],address)']([fundWallet], C20.address).encodeABI();
  proxyAdmin = await ProxyAdmin.deployed();

  await deployer.deploy(C20InvestProxy, c20InvestLogic.address, proxyAdmin.address, calldata);
  const c20InvestProxy = await C20InvestProxy.deployed();

  const proxyCon = await C20Invest.at(c20InvestProxy.address);
  console.log(proxyCon.address);
};
