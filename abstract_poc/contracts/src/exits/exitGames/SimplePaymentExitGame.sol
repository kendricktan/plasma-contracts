pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./BaseExitGame.sol";
import "../models/SimplePaymentExitDataModel.sol";
import "../models/SimplePaymentExitDataModel.sol";
import "../../framework/interfaces/OutputPredicate.sol";
import "../../transactions/outputs/PaymentOutputModel.sol";
import "../../transactions/txs/SimplePaymentTxModel.sol";

/**
 Using MoreVp, POC skiping IFE
 */
contract SimplePaymentExitGame is BaseExitGame {
    uint256 constant TX_TYPE = 1;
    uint8 STANDARD_EXIT_TYPE = 1;
    uint8 INFLIGHT_EXIT_TYPE = 2;

    using PaymentOutputModel for PaymentOutputModel.TxOutput;

    constructor(address _framework, address _exitProcessor)
        BaseExitGame(_framework, _exitProcessor) public {}

    function startStandardExit(uint192 _utxoPos, bytes calldata _outputTx, bytes calldata _outputTxInclusionProof)
        external onlyFromFramework {
        //TODO: check inclusion proof

        // If we are using ABIEncoderV2, I think we can even pass in the struct directly instead of bytes then there is no need to decode (?)
        SimplePaymentTxModel.Tx memory outputTx = SimplePaymentTxModel.decode(_outputTx);

        uint256 exitId = uint(_utxoPos); // This does not work with IFE, temp for prototype
        uint256 exitableAt = block.timestamp; // Need to add a period, for prototype we make it insecure
        ExitModel.Exit memory exit = ExitModel.Exit(exitProcessor, exitableAt, exitId);
        uint192 priority = _utxoPos;
        framework.enqueue(priority, exit);

        uint256 outputIndex = 0; // simple payment tx only have 1 input and output. Otherwise should parse this from _utxoPos
        SimplePaymentExitDataModel.Data memory exitData = SimplePaymentExitDataModel.Data({
            exitId: exitId,
            exitType: STANDARD_EXIT_TYPE,
            exitable: true,
            outputHash: outputTx.outputs[outputIndex].hash(),
            token: outputTx.outputs[outputIndex].outputData.token,
            exitTarget: address(uint160(outputTx.outputs[outputIndex].outputData.owner)),
            amount: outputTx.outputs[outputIndex].outputData.amount
        });

        bytes memory exitDataInBytes = abi.encode(exitData);
        framework.setBytesStorage(TX_TYPE, bytes32(exitId), exitDataInBytes);
        emit ExitStarted(exitId, STANDARD_EXIT_TYPE);
    }

    function challengeStandardExitOutputUsed(
        uint192 _standardExitId,
        bytes calldata _output,
        bytes calldata _challengeTx,
        uint256 _challengeTxType,
        uint8 _inputIndex
    ) external onlyFromFramework {
        uint256 exitId = uint256(_standardExitId);
        bytes memory exitDataInBytes = framework.getBytesStorage(TX_TYPE, bytes32(exitId));
        SimplePaymentExitDataModel.Data memory exitData = abi.decode(exitDataInBytes, (SimplePaymentExitDataModel.Data));

        require(exitData.exitType == STANDARD_EXIT_TYPE, "The exit is not standard exit.");
        require(exitData.outputHash == keccak256(_output), "The output does not match the exit output");

        OutputPredicate predicate = framework.getOutputPredicate(PaymentOutputModel.getOutputType(), _challengeTxType);
        require(predicate.canUseTxOutput(_output, _challengeTx, _inputIndex), "The output is not able to be used in the challenge tx");

        exitData.exitable = false;
        framework.setBytesStorage(TX_TYPE, bytes32(exitId), abi.encode(exitData));
    }
}
