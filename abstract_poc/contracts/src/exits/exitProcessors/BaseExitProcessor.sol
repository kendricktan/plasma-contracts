pragma solidity ^0.5.0;

import "../../framework/PlasmaFramework.sol";
import "../../framework/interfaces/ExitProcessor.sol";

contract BaseExitProcessor is ExitProcessor {
    PlasmaFramework framework;
    uint256 txType;

    modifier onlyFromFramework() {
        require(msg.sender == address(framework), "Not being called from the PlasmaFramework");
        _;
    }

    constructor(address _framework, uint256 _txType) public {
        framework = PlasmaFramework(_framework);
        txType = _txType;
    }
}