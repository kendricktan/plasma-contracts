pragma solidity ^0.5.0;

import "./ExitGameRegistry.sol";
import "./ExitProcessorRegistry.sol";
import "./OutputPredicateRegistry.sol";
import "./VaultRegistry.sol";

contract Registry is ExitGameRegistry, ExitProcessorRegistry, OutputPredicateRegistry, VaultRegistry {
}