pragma solidity ^0.5.0;

import "../registries/ExitGameRegistry.sol";

contract ExitGameWhitelisted is ExitGameRegistry {

    modifier onlyExitGame() {
        require(getTxTypeFromExitGame(msg.sender) != 0, "Not being called by the ExitGame contract");
        _;
    }
}