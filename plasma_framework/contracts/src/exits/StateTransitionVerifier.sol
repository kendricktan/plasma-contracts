pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import './IStateTransitionVerifier.sol';
import './ITransactionRegistry.sol';
import './StateTransitionVerifierRegistry.sol';
import './Universal.sol';
import '../utils/UtxoPosLib.sol';

/*
* This verifier implements a logic that should not change
* like checking if transaction does not overspend
* tx type specific transition logic verification is moved into a specific implementation of TransactionVerifier
* that can be registered changed for any tx type.
*/
contract StateTransitionVerifier is IStateTransitionVerifier, StateTransitionVerifierRegistry {

    ITransactionRegistry transactionRegistry;

    constructor(ITransactionRegistry _transactionRegistry) public {
        transactionRegistry = _transactionRegistry;
    }

    /**
    * @notice Verifies state transition logic.
    */
    function isCorrectStateTransition(
        uint256 inFlightTxType,
        bytes calldata inFlightTx,
        bytes[] calldata inputTxs,
        uint256[] calldata inputTxsTypes,
        uint256[] calldata inputUtxosPos
    )
        external
        view
        returns (Universal.WithdrawData[] memory)
    {
        // check if inputs sum >= outputs sum
        // WithdrawData would be something that can be extracted for every (txType, outputType) pair
        // and could be used as argument type for all our interfaces
        // I would move it to transaction folder and probably rename it
        Universal.WithdrawData[] memory inputs = getOutputsFromInputTxs(inputTxs, inputTxsTypes, inputUtxosPos);
        Universal.WithdrawData[] memory outputs = getAllOutputsFromTx(inFlightTxType, inFlightTx);
        for (uint i = 0; i < outputs.length; i++) {
            address token = outputs[i].token;
            Universal.WithdrawData[] memory inputsForToken = getWithToken(inputs, token);
            Universal.WithdrawData[] memory outputsForToken = getWithToken(outputs, token);
            // I'd like to have an interface that picks a vault based on token.
            // We already have vaults for Ethereum and ERC20 tokens, we could add one for ERC721 if needed
            // We should have a mapping between tokens and specific vault so we know which one to choose here (and choosing logic could be implemented in VaultRegistry)
            // I think checking if transaction overspends a specific token could be verified in a vault for that token

            //require(vault.isCorrectTransition(inputsForToken, outputsForToken), "Transaction is not a correct transition");
        }

        // tx type dependant, non generic checks are pushed into a specific transition verifier
        IStateTransitionVerifier specificVerifier = transitionVerifier(inFlightTxType);
        specificVerifier.isCorrectStateTransition(inFlightTx, inputTxs, inputTxsTypes, inputUtxosPos);

        return inputs;
    }

    function getOutputsFromInputTxs(
        bytes[] memory inputTxs,
        uint256[] memory inputTxsTypes,
        uint256[] memory inputUtxosPos
    )
        private
        view
        returns (Universal.WithdrawData[] memory)
    {
        Universal.WithdrawData[] memory outputs = new Universal.WithdrawData[](inputTxs.length);
        for (uint i = 0; i < inputTxs.length; i++) {
            Universal.WithdrawData memory output = getOutput(inputTxsTypes[i], inputTxs[i], inputUtxosPos[i]);
            outputs[i] = output;
        }
        return outputs;
    }

    function getOutput(uint256 txType, bytes memory transaction, uint256 utxoPos) private view returns (Universal.WithdrawData memory) {
        ITransaction transactionInterface = transactionRegistry.transactionInterface(txType);
        uint16 outputIndex = UtxoPosLib.outputIndex(UtxoPosLib.UtxoPos(utxoPos));
        return transactionInterface.getOutput(transaction, outputIndex);
    }

    function getAllOutputsFromTx(uint256 txType, bytes memory transaction) private view returns (Universal.WithdrawData[] memory) {
        ITransaction transactionInterface = transactionRegistry.transactionInterface(txType);
        return transactionInterface.getOutputs(transaction);
    }

    function getWithToken(Universal.WithdrawData[] memory withdrawData, address token) private view returns (Universal.WithdrawData[] memory) {
    }
}
