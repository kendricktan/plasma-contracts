pragma solidity ^0.5.0;

import "../../../src/framework/registries/ExitGameRegistry.sol";

contract ExitGameRegistryMock is ExitGameRegistry {
    constructor (uint256 _minExitPeriod, uint256 _initialImmuneExitGames)
        ExitGameRegistry(_minExitPeriod, _initialImmuneExitGames) public {
    }

    function checkOnlyFromNonQuarantinedExitGame() public onlyFromNonQuarantinedExitGame view returns (bool) {
        return true;
    }
}
