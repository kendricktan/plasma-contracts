pragma solidity ^0.5.0;

import "../../framework/PlasmaFramework.sol";
import "../../framework/interfaces/ExitProcessor.sol";

contract BaseExitProcessor is ExitProcessor {
    PlasmaFramework framework;

    modifier onlyFromFramework() {
        require(msg.sender == address(framework), "Not being called from the PlasmaFramework");
        _;
    }

    constructor(address _framework) public {
        framework = PlasmaFramework(_framework);
    }
}