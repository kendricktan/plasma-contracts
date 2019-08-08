pragma solidity ^0.5.0;

import "../utils/RLP.sol";

/**
 * @title WireTransaction
 * @dev Utility functions for working with transactions in wire format.
 */
library WireTransaction {

    using RLP for bytes;
    using RLP for RLP.RLPItem;

    struct Output {
        bytes32 outputGuard;
        address token;
        uint256 amount;
    }

    /**
    * @notice Returns transaction type for transaction in wire format.
    * @dev Uses the fact that in wire format transactino type is the first element of RLP encoded list.
    */
    function getTransactionType(bytes memory transaction) internal pure returns (uint256) {
       RLP.RLPItem[] memory rlpTx = transaction.toRLPItem().toList();
       return rlpTx[0].toUint();
    }

    function getOutput(bytes memory transaction, uint16 outputIndex) internal pure returns (Output memory) {
        RLP.RLPItem[] memory rlpTx = transaction.toRLPItem().toList();
        RLP.RLPItem[] memory outputs = rlpTx[2].toList();
        require(outputIndex < outputs.length, "Invalid wire transaction format");

        RLP.RLPItem[] memory output = outputs[outputIndex].toList();
        bytes32 outputGuard = output[0].toBytes32();
        address token = output[1].toAddress();
        uint256 amount = output[2].toUint();

        return Output(outputGuard, token, amount);
    }
}
