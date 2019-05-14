pragma solidity ^0.5.0;

import "../../framework/PlasmaFramework.sol";

contract BaseExitGame {
    PlasmaFramework framework;
    address exitProcessor;
    uint256 txType;

    modifier onlyFromFramework() {
        require(msg.sender == address(framework), "Not being called from the PlasmaFramework");
        _;
    }

    constructor(address _framework, address _exitProcessor, uint256 _txType) public {
        framework = PlasmaFramework(_framework);
        exitProcessor = _exitProcessor;
        txType = _txType;
    }
}