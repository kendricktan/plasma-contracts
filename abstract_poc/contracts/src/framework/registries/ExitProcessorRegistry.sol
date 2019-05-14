pragma solidity ^0.5.0;

import "../PlasmaStorage.sol";
import "../modifiers/Operated.sol";

contract ExitProcessorRegistry is PlasmaStorage, Operated {
    function registerExitProcessor(uint256 _txType, address _contractAddress, uint256 _version) public onlyOperator {
        bytes32 key = keccak256(abi.encodePacked(_txType, _version));
        exitProcessorsAllVersions[key] = _contractAddress;
    }

    function getExitProcessorByVersion(uint256 _txType, uint256 _version) public view returns (address) {
        bytes32 key = keccak256(abi.encodePacked(_txType, _version));
        return exitProcessorsAllVersions[key];
    }

    // use this function to upgrade, need to check the whether the version is registered > 2 weeks
    function upgradeExitProcessorTo(uint256 _txType, uint256 _version) public onlyOperator returns (address) {
        // TODO: check 2 week (or any safe period)

        bytes32 key = keccak256(abi.encodePacked(_txType, _version));
        address newAddress = exitProcessorsAllVersions[key];
        address oldAddress = exitProcessorsCurrentVersion[_txType];
        
        exitProcessorToTxType[oldAddress] = 0;
        exitProcessorToTxType[newAddress] = _txType;
        exitGamesCurrentVersion[_txType] = newAddress;
        
        return newAddress;
    }

    // this returns the current version
    function getExitProcessor(uint256 _txType) public view returns (address) {
        return exitProcessorsCurrentVersion[_txType];
    }

    function getTxTypeFromExitProcessor(address _contractAddress) public view returns (uint256) {
        return exitProcessorToTxType[_contractAddress];
    }
}
