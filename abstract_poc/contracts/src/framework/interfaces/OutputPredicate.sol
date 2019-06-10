pragma solidity ^0.5.0;

interface OutputPredicate {
    /**
     * @dev Checks whether a output can be used in next tx.
     * @param _txOutput tx output data.
     * @param _consumeTx tx that consumes the targeting tx output.
     * @param _inputIndex index for the input of consuming tx that uses the tx output.
     */
    function canUseTxOutput(bytes calldata _txOutput, bytes calldata _consumeTx, uint8 _inputIndex, bytes calldata _witness) external returns (bool);
}
