pragma solidity ^0.5.0;

import "../PlasmaStorage.sol";
import "../modifiers/Operated.sol";

contract VaultRegistry is PlasmaStorage, Operated {
    function registerVault(uint256 _vaultId, address _contractAddress) public onlyOperator {
        vaults[_vaultId] = _contractAddress;
        vaultToId[_contractAddress] = _vaultId;
    }

    function getVault(uint256 _vaultId) public view returns (address) {
        return vaults[_vaultId];
    }

    function getVaultIdFromAddress(address _vaultAddress) public view returns (uint256) {
        return vaultToId[_vaultAddress];
    }
}
