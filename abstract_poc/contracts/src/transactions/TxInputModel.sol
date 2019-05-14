pragma solidity ^0.5.0;

library TxInputModel {
    struct TxInput {
        uint256 blknum;
        uint256 txindex;
        uint256 oindex;
    }
}