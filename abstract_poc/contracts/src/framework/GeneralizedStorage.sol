pragma solidity ^0.5.0;

import "./PlasmaStorage.sol";
import "./registries/ExitGameRegistry.sol";
import "./registries/ExitProcessorRegistry.sol";

/**
Use a generalized storage in plasma for all exit games to call.
TODO: all the getter, setter and deleter functions. Provide some basic sample only here.
See PlasmaStorage.sol for all gernalized storage map that need the functions.
 */
contract GeneralizedStorage is PlasmaStorage, ExitGameRegistry, ExitProcessorRegistry {

    function getBytesStorage(uint256 _txType, bytes32 _key) external view returns (bytes memory) {
        bytes32 key = keccak256(abi.encodePacked(_txType, _key));
        return bytesStorage[key];
    }

    function setBytesStorage(uint256 _txType, bytes32 _key, bytes calldata _value) external {
        require(msg.sender == getExitGame(_txType) || msg.sender == getExitProcessor(_txType),
            "Generalized Storage must be called by registered contracts accordingly");
        bytes32 key = keccak256(abi.encodePacked(_txType, _key));
        bytesStorage[key] = _value;
    }

    function deleteBytesStorage(uint256 _txType, bytes32 _key) external {
        require(msg.sender == getExitGame(_txType) || msg.sender == getExitProcessor(_txType),
            "Generalized Storage must be called by registered contracts accordingly");
        bytes32 key = keccak256(abi.encodePacked(_txType, _key));
        delete bytesStorage[key];
    }
}