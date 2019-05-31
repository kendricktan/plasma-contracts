pragma solidity ^0.5.0;

import "../WithFramework.sol";
import "../framework/PlasmaFramework.sol";

contract OnlyExitProcessor is WithFramework {
    modifier onlyExitProcessor() {
        PlasmaFramework framework = this.framework();
        require(framework.getTxTypeFromExitProcessor(msg.sender) != 0, "Can only be called from registered ExitProcessors.");
        _;
    }
}