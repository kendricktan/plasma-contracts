const PriorityQueueLib = artifacts.require("PriorityQueueLib");
const PlasmaFramework = artifacts.require("PlasmaFramework");
const PaymentOutputModel = artifacts.require("PaymentOutputModel");
const TxInputModel = artifacts.require("TxInputModel");
const SimplePaymentExitGame = artifacts.require("SimplePaymentExitGame");
const SimplePaymentTxModel = artifacts.require("SimplePaymentTxModel");
const SimplePaymentExitProcessor = artifacts.require("SimplePaymentExitProcessor");
const EthVault = artifacts.require("EthVault");
const RLP = artifacts.require("RLP");
const RLPTest = artifacts.require("RLPTest");
const ZeroHashesProvider = artifacts.require("ZeroHashesProvider");
const PaymentOutputToPaymentTxPredicate = artifacts.require("PaymentOutputToPaymentTxPredicate");

const FundingExitGame = artifacts.require("FundingExitGame");

module.exports = async (deployer) => {
  await deployer.deploy(PriorityQueueLib);
  await deployer.link(PriorityQueueLib, PlasmaFramework);
  await deployer.deploy(PlasmaFramework);

  await deployer.deploy(RLP);

  await deployer.link(RLP, [RLPTest, PaymentOutputModel, TxInputModel, SimplePaymentTxModel]);
  await deployer.deploy(RLPTest);

  await deployer.deploy(PaymentOutputModel);
  await deployer.deploy(PaymentOutputToPaymentTxPredicate);

  await deployer.deploy(TxInputModel);

  await deployer.link(PaymentOutputModel, [SimplePaymentTxModel, SimplePaymentExitGame]);
  await deployer.link(TxInputModel, SimplePaymentTxModel);
  await deployer.deploy(SimplePaymentTxModel);
  await deployer.link(SimplePaymentTxModel, EthVault);

  await deployer.deploy(ZeroHashesProvider);
  await deployer.link(ZeroHashesProvider, EthVault);
  await deployer.deploy(EthVault, PlasmaFramework.address);

  await deployer.deploy(SimplePaymentExitProcessor, PlasmaFramework.address, EthVault.address);
  await deployer.deploy(SimplePaymentExitGame, PlasmaFramework.address, SimplePaymentExitProcessor.address);
};
