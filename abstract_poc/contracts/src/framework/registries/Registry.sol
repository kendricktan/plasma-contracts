pragma solidity ^0.5.0;

import "./ExitGameRegistry.sol";
import "./ExitProcessorRegistry.sol";
import "./OutputPredicateRegistry.sol";

contract Registry is ExitGameRegistry, ExitProcessorRegistry, OutputPredicateRegistry {
}