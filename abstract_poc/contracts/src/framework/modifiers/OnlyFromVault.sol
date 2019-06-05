pragma solidity ^0.5.0;

import "../PlasmaStorage.sol";

contract OnlyFromVault is PlasmaStorage {
    modifier onlyFromVault() {
        require(vaultToId[msg.sender] != 0, "Not from registered vault");
        _;
    }
}