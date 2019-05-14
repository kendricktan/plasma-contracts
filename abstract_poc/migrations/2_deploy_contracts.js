const PriorityQueueLib = artifacts.require("PriorityQueueLib");
const PlasmaFramework = artifacts.require("PlasmaFramework");

module.exports = function(deployer) {
  deployer.deploy(PriorityQueueLib);
  deployer.link(PriorityQueueLib, PlasmaFramework);
  deployer.deploy(PlasmaFramework);
};
