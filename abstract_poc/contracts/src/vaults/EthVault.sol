pragma solidity ^0.5.0;

import "./OnlyExitProcessor.sol";
import "./ZeroHashesProvider.sol";
import "../WithFramework.sol";
import "../framework/PlasmaFramework.sol";
import {SimplePaymentTxModel as DepositTx} from "../transactions/txs/SimplePaymentTxModel.sol";

contract EthVault is WithFramework, OnlyExitProcessor {
    PlasmaFramework private framework;
    bytes32[16] zeroHashes;

    using DepositTx for DepositTx.Tx;

    constructor(address _framework) public {
        framework = PlasmaFramework(_framework);
        zeroHashes = ZeroHashesProvider.getZeroHashes();
    }

    /**
     * @dev Allows a user to submit a deposit.
     * @param _depositTx RLP encoded transaction to act as the deposit.
     */
    function deposit(bytes calldata _depositTx) external payable {
        DepositTx.Tx memory decodedTx = DepositTx.decode(_depositTx);

        (bool isFormatValid, string memory message) = decodedTx.checkFormat();
        require(isFormatValid, message);

        //TODO: ignore this check in POC
        //require(decodedTx.outputs[0].outputData.amount == msg.value, "First output does not has correct value as msg.value");

        require(decodedTx.outputs[0].outputData.token == address(0), "First output does not has correct currency (ETH)");

        bytes32 root = keccak256(_depositTx);
        for (uint i = 0; i < 16; i++) {
            root = keccak256(abi.encodePacked(root, zeroHashes[i]));
        }

        framework.submitDepositBlock(root);
    }

    /**
    * @dev Withdraw plasma chain eth via transferring ETH.
    * @param _target Place to transfer eth.
    * @param _amount Amount of eth to transfer.
    */
    function withdraw(address payable _target, uint256 _amount) external onlyExitProcessor {
        _target.transfer(_amount);
    }
}