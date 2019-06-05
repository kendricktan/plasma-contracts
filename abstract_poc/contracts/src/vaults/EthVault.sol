pragma solidity ^0.5.0;

import "./ZeroHashesProvider.sol";
import "../WithFramework.sol";
import "../framework/PlasmaFramework.sol";
import {SimplePaymentTxModel as DepositTx} from "../transactions/txs/SimplePaymentTxModel.sol";

contract EthVault {
    PlasmaFramework framework;
    bytes32[16] zeroHashes;

    modifier onlyExitProcessor() {
        require(framework.getTxTypeFromExitProcessor(msg.sender) != 0, "Can only be called from registered ExitProcessors.");
        _;
    }

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

        require(decodedTx.outputs[0].outputData.amount == msg.value, "Deposited value does not match sent amount");

        require(decodedTx.outputs[0].outputData.token == address(0), "First output does not have correct currency (ETH)");

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
    function withdraw(address payable _target, uint256 _amount) external onlyExitProcessor() {
        _target.transfer(_amount);
    }
}
