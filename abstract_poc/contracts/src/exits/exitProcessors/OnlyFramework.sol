pragma solidity ^0.5.0;

import "../../WithFramework.sol";
import "../../framework/interfaces/ExitProcessor.sol";

contract OnlyFramework is WithFramework {
    modifier onlyFramework() {
        require(msg.sender == address(this.framework()), "Not being called from the PlasmaFramework");
        _;
    }
}