pragma solidity ^0.5.0;

import "../PlasmaStorage.sol";
import "../interfaces/OutputPredicate.sol";
import "../modifiers/Operated.sol";

contract OutputPredicateRegistry is PlasmaStorage, Operated {
    function registerOutputPredicate(
        uint256 _outputType, uint256 _consumeTxType, address _contractAddress, uint256 _version
    ) public onlyOperator {
        bytes32 key = keccak256(abi.encodePacked(_outputType, _consumeTxType, _version));
        outputPredicatesAllVersion[key] = _contractAddress;
    }

    function getOutputPredicateByVersion(uint256 _outputType, uint256 _consumeTxType, uint256 _version) public view returns (address) {
        bytes32 key = keccak256(abi.encodePacked(_outputType, _consumeTxType, _version));
        return outputPredicatesAllVersion[key];
    }

    // use this function to upgrade, need to check the whether the version is registered > 2 weeks
    function upgradeOutputPredicateTo(
        uint256 _outputType, uint256 _consumeTxType, uint256 _version
    ) public onlyOperator returns (address) {
        bytes32 keyAllVersion = keccak256(abi.encodePacked(_outputType, _consumeTxType, _version));
        bytes32 keyCurrentVersion = keccak256(abi.encodePacked(_outputType, _consumeTxType));

        return outputPredicatesCurrentVersion[keyCurrentVersion] = outputPredicatesAllVersion[keyAllVersion];
    }

    // this returns the current version
    function getOutputPredicate(uint256 _outputType, uint256 _consumeTxType) public view returns (OutputPredicate) {
        bytes32 key = keccak256(abi.encodePacked(_outputType, _consumeTxType));
        return OutputPredicate(outputPredicatesCurrentVersion[key]);
    }
}
