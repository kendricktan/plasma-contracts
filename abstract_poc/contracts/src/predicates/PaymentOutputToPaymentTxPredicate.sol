pragma solidity ^0.5.0;

import "../framework/interfaces/OutputPredicate.sol";
import "../transactions/txs/SimplePaymentTxModel.sol";
import "../transactions/outputs/PaymentOutputModel.sol";
import "../utils/ECRecovery.sol";

contract PaymentOutputToPaymentTxPredicate is OutputPredicate {
    function canUseTxOutput(bytes calldata _txOutput, bytes calldata _consumeTx, uint8 _inputIndex, bytes calldata _witness) external returns (bool) {
        /**
        1. use `inputIndex` to get proof data (signature) from tx
        2. prove signature correct (output.owner == ERCRecover.recover(...))
        3. return true, false accordingly
         */

        // It's down to exit game and predicate what particular witness represents (an array of signatures, a single model object, etc.)
        // I would go for singular form 'witness' instead of 'witnesses'

        SimplePaymentTxModel.Witness memory witness = SimplePaymentTxModel.decodeWitness(_witness);

        PaymentOutputModel.TxOutput memory output = PaymentOutputModel.decodeOutput(_txOutput);
        bytes32 consumeTxHash = keccak256(_consumeTx);
        return output.outputData.owner == ECRecovery.recover(consumeTxHash, witness.signature);
    }
}
