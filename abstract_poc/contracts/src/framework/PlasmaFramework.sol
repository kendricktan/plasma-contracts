pragma solidity ^0.5.0;

// Should be safe to use. It is marked as experimental as it costs higher gas usage.
// see: https://github.com/ethereum/solidity/issues/5397
pragma experimental ABIEncoderV2;

import "./PlasmaStorage.sol";
import "./GeneralizedStorage.sol";
import "./PlasmaBlockController.sol";
import "./ExitGameController.sol";
import "./PlasmaWallet.sol";
import "./priorityQueue/PriorityQueue.sol";
import "./registries/Registry.sol";
import "./modifiers/Operated.sol";

contract PlasmaFramework is PlasmaStorage, Operated, GeneralizedStorage, PlasmaBlockController, PlasmaWallet, Registry, ExitGameController {
    constructor() public {
        _initOperator();

        nextChildBlock = CHILD_BLOCK_INTERVAL;
        nextDepositBlock = 1;

        queue = new PriorityQueue(address(this));

        // This is some optimization while building merkle tree for deposit block
        // Pre-compute the essential data once and reuse in every deposit
        bytes32 zeroHash = keccak256(abi.encodePacked(uint256(0)));
        for (uint i = 0; i < 16; i++) {
            zeroHashes[i] = zeroHash;
            zeroHash = keccak256(abi.encodePacked(zeroHash, zeroHash));
        }
    }
}