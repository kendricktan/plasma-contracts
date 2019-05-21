pragma solidity ^0.5.0;

import "../../framework/PlasmaFramework.sol";

contract BaseExitGame {
    PlasmaFramework framework;
    address exitProcessor;

    event ExitStarted(
        uint256 exitId,
        uint8 exitType
    );

    modifier onlyFromFramework() {
        require(msg.sender == address(framework), "Not being called from the PlasmaFramework");
        _;
    }

    constructor(address _framework, address _exitProcessor) public {
        framework = PlasmaFramework(_framework);
        exitProcessor = _exitProcessor;
    }
}
