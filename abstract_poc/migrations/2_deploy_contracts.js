const PriorityQueueLib = artifacts.require("PriorityQueueLib");
const PlasmaFramework = artifacts.require("PlasmaFramework");
const PaymentOutputToPaymentTxPredicate = artifacts.require("PaymentOutputToPaymentTxPredicate");
const PaymentOutputModel = artifacts.require("PaymentOutputModel");
const SimplePaymentExitGame = artifacts.require("SimplePaymentExitGame");
const SimplePaymentExitProcessor = artifacts.require("SimplePaymentExitProcessor");
const RLPTest = artifacts.require("RLPTest");

const FundingExitGame = artifacts.require("FundingExitGame");

module.exports = async (deployer) => {
  deployer.deploy(PriorityQueueLib);
  deployer.link(PriorityQueueLib, PlasmaFramework);
  await deployer.deploy(PlasmaFramework);

  deployer.deploy(PaymentOutputModel);
  deployer.deploy(PaymentOutputToPaymentTxPredicate);
  await deployer.deploy(SimplePaymentExitProcessor, PlasmaFramework.address);
  deployer.link(PaymentOutputModel, SimplePaymentExitGame);
  await deployer.deploy(SimplePaymentExitGame, PlasmaFramework.address, SimplePaymentExitProcessor.address);
  await deployer.deploy(RLPTest);
};
