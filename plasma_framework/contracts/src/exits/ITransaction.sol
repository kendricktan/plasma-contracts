pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import './Universal.sol';

// File should probably be placed somewhere in transaction folder
// Interface that understands structure of transaction for a fixed tx type
// Returns values of types that are understood in plasma framework like WithdrawData (name to change), etc.

interface ITransaction {

    /**
    * @notice Returns output for a given transaction and output index.
    */
    function getOutput(bytes calldata transaction, uint256 outputIndex) external view returns (Universal.WithdrawData memory);

    /**
    * @notice Returns all output for a given transaction.
    */
    function getOutputs(bytes calldata transaction) external view returns (Universal.WithdrawData[] memory);
}
