pragma solidity ^0.5.0;

interface TxOutputPredicate {
    /**
     * @dev Checks whether a output can be used in next tx.
     * @param _txOutput tx output data.
     * @param _consumeTx tx that consumes the targeting tx output.
     */
    function canUseTxOutput(bytes calldata _txOutput, bytes calldata _consumeTx) external returns (bool);
}