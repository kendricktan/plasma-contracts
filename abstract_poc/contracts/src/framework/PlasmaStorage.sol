pragma solidity ^0.5.0;

import "./models/ExitModel.sol";
import "./models/BlockModel.sol";
import "./priorityQueue/PriorityQueue.sol";

/**
Centralized place to hold all Plasma storages.
If we want to use proxy contract upgrade on the plasma layer,
we need to make the the order of storage declaration can be only appended.
When upgrade, should just extends this storage to v2 and add new storage
defintions to maker sure the storage layout does not break.
Put everything in a centralizec place to avoid possible future crash.
 */
contract PlasmaStorage {
    /**
    Basic Plasma
    */
    address public operator;

    uint256 constant public CHILD_BLOCK_INTERVAL = 1000;

    mapping (uint256 => BlockModel.Block) public blocks;
    uint256 public nextChildBlock;
    uint256 public nextDepositBlock;

    PriorityQueue public queue;

    bytes32[16] zeroHashes;

    /**
    Generalize storage
     */
    mapping(bytes32 => uint256) internal uIntStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

    /**
    Exit Game Controller
     */
    uint128 internal exitQueueNonce;
    mapping(uint256 => ExitModel.Exit) internal exits;
    mapping(address => address) public exitsQueues;

    /**
    Exit Game Registry
     */
    mapping(uint256 => address) internal exitGamesCurrentVersion;
    mapping(bytes32 => address) internal exitGamesAllVersions;
    mapping(address => uint256) internal exitGameToTxType;

    /**
    Exit Processor Registry
     */
    mapping(uint256 => address) internal exitProcessorsCurrentVersion;
    mapping(bytes32 => address) internal exitProcessorsAllVersions;
    mapping(address => uint256) internal exitProcessorToTxType;

    /**
    TxOutput Predicate Registry
     */
    mapping(bytes32 => address) internal outputPredicatesCurrentVersion;
    mapping(bytes32 => address) internal outputPredicatesAllVersion;
}