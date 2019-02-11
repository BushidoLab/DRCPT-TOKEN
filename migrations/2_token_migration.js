const DRCPT = artifacts.require("./DRCPT.sol");
const DRCPTCrowdsale = artifacts.require("./DRCPTCrowdsale.sol");
const { test, production } = require("../config.js");


module.exports = deployer => {
  deployer.deploy(DRCPT, "DRCPT", "DRCPT", 18, 1000000000).then(async ()=>{
    return deployer.deploy(
      DRCPTCrowdsale,
      (await web3.eth.getAccounts())[0], // Treasury address
      [
        test.privateSaleEnd,
        test.preICOEnd,
        test.ico1End,
        test.ico2End,
        test.ico3End,
        test.liveEnd
      ],
      DRCPT.address // Token address
    );
  });
};
