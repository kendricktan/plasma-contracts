pragma solidity ^0.5.0;

import "../registries/ExitProcessorRegistry.sol";

contract ExitProcessorWhitelisted is ExitProcessorRegistry {

    modifier onlyExitProcessor() {
        require(getTxTypeFromExitProcessor(msg.sender) != 0, "Not being called by the ExitProcessor contract");
        _;
    }
}