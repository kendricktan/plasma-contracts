const PriorityQueueLib = artifacts.require("PriorityQueueLib");
const PlasmaFramework = artifacts.require("PlasmaFramework");
const PaymentOutputToPaymentTxPredicate = artifacts.require("PaymentOutputToPaymentTxPredicate");
const PaymentOutputModel = artifacts.require("PaymentOutputModel");
const DexOutputModel = artifacts.require("DexOutputModel");
const SimplePaymentExitGame = artifacts.require("SimplePaymentExitGame");
const SimplePaymentExitProcessor = artifacts.require("SimplePaymentExitProcessor");
const FundingExitGame = artifacts.require("FundingExitGame");
const FundingExitProcessor = artifacts.require("FundingExitProcessor");

module.exports = async (deployer) => {
  deployer.deploy(PriorityQueueLib);
  deployer.link(PriorityQueueLib, PlasmaFramework);
  await deployer.deploy(PlasmaFramework);

  deployer.deploy(PaymentOutputModel);
  deployer.deploy(PaymentOutputToPaymentTxPredicate);
  await deployer.deploy(SimplePaymentExitProcessor, PlasmaFramework.address);
  deployer.link(PaymentOutputModel, SimplePaymentExitGame);
  await deployer.deploy(SimplePaymentExitGame, PlasmaFramework.address, SimplePaymentExitProcessor.address);

  deployer.deploy(DexOutputModel);
  await deployer.deploy(FundingExitProcessor, PlasmaFramework.address);
  deployer.link(DexOutputModel, FundingExitGame);
  await deployer.deploy(FundingExitGame, PlasmaFramework.address, FundingExitProcessor.address);
};
