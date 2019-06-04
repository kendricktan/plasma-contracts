pragma solidity ^0.5.0;

import "../../models/SimplePaymentExitDataModelV2.sol";
import "../../../transactions/txs/SimplePaymentTxModel.sol";
import "../../../transactions/TxInputModel.sol";
import "../../../utils/ECRecovery.sol";

library PaymentOutputToPaymentTxCondition {
    using TxInputModel for TxInputModel.TxInput;

    function check(
        SimplePaymentExitDataModelV2.Data memory _exitData,
        bytes memory _consumeTx,
        uint256 _inputIndex
    ) internal pure {
        SimplePaymentTxModel.Tx memory consumeTx = SimplePaymentTxModel.decode(_consumeTx);
        uint256 utxoPos = consumeTx.inputs[_inputIndex].toUtxoPos();
        require(utxoPos == _exitData.outputId, "UTXO Position does not match the exit data's output id");

        bytes32 txHash = keccak256(_consumeTx);
        bytes memory sig = consumeTx.witnesses[_inputIndex].signature;
        require(_exitData.exitTarget == ECRecovery.recover(txHash, sig), "signature incorrect");
    }
}