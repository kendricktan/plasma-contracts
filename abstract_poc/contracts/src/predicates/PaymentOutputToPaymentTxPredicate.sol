pragma solidity ^0.5.0;

import "../framework/interfaces/OutputPredicate.sol";

contract PaymentOutputToPaymentTxPredicate is OutputPredicate {
    function canUseTxOutput(bytes calldata _txOutput, bytes calldata _consumeTx, uint8 _inputIndex) external returns (bool) {
        /**
        1. use `inputIndex` to get proof data (signature) from tx
        2. prove signature correct (output.owner == ERCRecover.recover(...))
        3. return true, false accordingly
         */
        return true;
    }
}