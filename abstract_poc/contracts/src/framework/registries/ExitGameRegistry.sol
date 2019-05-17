pragma solidity ^0.5.0;

import "../PlasmaStorage.sol";
import "../modifiers/Operated.sol";

contract ExitGameRegistry is PlasmaStorage, Operated {
    /**
     * @dev Register an app to the MoreVp Plasma framework. This can be only called by contract admin.
     * @param _txType tx type that uses the exit game.
     * @param _contractAddress Address of the app contract.
     * @param _version version of the contract.
     */
    function registerExitGame(uint256 _txType, address _contractAddress, uint256 _version) public onlyOperator {
        bytes32 key = keccak256(abi.encodePacked(_txType, _version));
        exitGamesAllVersions[key] = _contractAddress;
    }

    function getExitGameByVersion(uint256 _txType, uint256 _version) public view returns (address) {
        bytes32 key = keccak256(abi.encodePacked(_txType, _version));
        return exitGamesAllVersions[key];
    }

    // use this function to upgrade, need to check the whether the version is registered > 2 weeks
    function upgradeExitGameTo(uint256 _txType, uint256 _version) public onlyOperator returns (address) {
        address newAddress = getExitGameByVersion(_txType, _version);
        address oldAddress = exitGamesCurrentVersion[_txType];

        exitGameToTxType[oldAddress] = 0;
        exitGameToTxType[newAddress] = _txType;
        exitGamesCurrentVersion[_txType] = newAddress;

        return newAddress;
    }

    // this returns the current version
    function getExitGame(uint256 _txType) public view returns (address) {
        return exitGamesCurrentVersion[_txType];
    }

    function getTxTypeFromExitGame(address _contractAddress) public view returns (uint256) {
        return exitGameToTxType[_contractAddress];
    }
}
