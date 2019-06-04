pragma solidity ^0.5.0;

library TxInputModel {
    uint256 constant internal BLOCK_OFFSET = 1000000000;
    uint256 constant internal TX_OFFSET = 10000;

    struct TxInput {
        uint256 blknum;
        uint256 txindex;
        uint256 oindex;
    }

    function toUtxoPos(TxInput memory _input) internal pure returns (uint256) {
        return _input.blknum * BLOCK_OFFSET + _input.txindex * TX_OFFSET + _input.oindex;
    }
}