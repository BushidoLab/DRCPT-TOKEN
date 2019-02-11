pragma solidity >= 0.4.21 < 0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/DRCPT.sol";

contract TestDRCPT {

    function testInitialBalanceUsingDeployedContract() public {
        DRCPT drcpt = DRCPT(DeployedAddresses.DRCPT());

        uint expected = 1000000000000000000000000000;

        Assert.equal(
          drcpt.balanceOf(msg.sender),
          expected,
          "Owner should have 10000 DRCPT initially"
        );
    }
}