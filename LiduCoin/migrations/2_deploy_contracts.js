
const DoMathLib = artifacts.require("DoMath");
const LiduCoin = artifacts.require('LiduCoin')

module.exports = function(deployer) {
  deployer.deploy(DoMathLib)
  deployer.link(DoMathLib,LiduCoin)
  deployer.deploy(LiduCoin)
};
