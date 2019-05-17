pragma solidity ^0.5.0;

import "./PlasmaBlockController.sol";
import "./utils/PlasmaCore.sol";
import "./models/BlockModel.sol";
import "./modifiers/ExitProcessorWhitelisted.sol";
import {SimplePaymentTxModel as DepositTx} from "../transactions/txs/SimplePaymentTxModel.sol";

contract PlasmaWallet is PlasmaStorage, ExitProcessorWhitelisted, PlasmaBlockController {
    using DepositTx for DepositTx.Tx;

    /**
     * @dev Allows a user to submit a deposit.
     * @param _depositTx RLP encoded transaction to act as the deposit.
     */
    function deposit(bytes calldata _depositTx) external payable {
        //TODO: probably we should call a predicate instead of checks
        //TODO: refactor to use predicates

        require(nextDepositBlock < CHILD_BLOCK_INTERVAL, "Exceed limit of deposits per child block interval");

        DepositTx.Tx memory decodedTx = DepositTx.decode(_depositTx);

        (bool isFormatValid, string memory message) = decodedTx.checkFormat();
        require(isFormatValid, message);

        //TODO: ignore this check in POC
        //require(decodedTx.outputs[0].outputData.amount == msg.value, "First output does not has correct value as msg.value");

        require(decodedTx.outputs[0].outputData.token == address(0), "First output does not has correct currency (ETH)");

        // Perform other checks and create a deposit block.
        _processDeposit(_depositTx, decodedTx);
    }

    /**
    * @dev Withdraw plasma chain eth via transferring ETH.
    * @param _target Place to transfer eth.
    * @param _amount Amount of eth to transfer.
    */
    function withdraw(address _target, uint256 _amount) external onlyExitProcessor {
        // TODO: implement
    }

    function _processDeposit(bytes memory _depositTx, DepositTx.Tx memory decodedTx) private {
        // Following check is needed since _processDeposit
        // can be called on stack unwinding during re-entrance attack,
        // with nextDepositBlock == 999, producing
        // deposit with blknum ending with 000.
        require(nextDepositBlock < CHILD_BLOCK_INTERVAL, "Exceed limit of deposits per child block interval");

        // Calculate the block root.
        bytes32 root = keccak256(_depositTx);
        for (uint i = 0; i < 16; i++) {
            root = keccak256(abi.encodePacked(root, zeroHashes[i]));
        }

        // Insert the deposit block.
        uint256 blknum = getDepositBlockNumber();
        blocks[blknum] = BlockModel.Block({
            root : root,
            timestamp : block.timestamp
        });

        nextDepositBlock++;

        // emit DepositCreated(
        //     decodedTx.outputs[0].owner,
        //     blknum,
        //     decodedTx.outputs[0].token,
        //     decodedTx.outputs[0].amount
        // );
    }
}