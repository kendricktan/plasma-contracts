pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import './ITransaction.sol';

// Registers interfaces for transaction types
// Works like any other of our registries
// File should place probably somewhere in transactions folder

interface ITransactionRegistry {

    /**
    * @notice Returns transaction interface for given transaction type.
    */
    function transactionInterface(uint256 txType) external view returns (ITransaction);
}
