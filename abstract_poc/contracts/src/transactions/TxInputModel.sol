pragma solidity ^0.5.0;

import "../utils/RLP.sol";

library TxInputModel {

    using RLP for bytes;
    using RLP for RLP.RLPItem;

    uint256 constant internal BLOCK_OFFSET = 1000000000;
    uint256 constant internal TX_OFFSET = 10000;

    struct TxInput {
        uint256 blknum;
        uint256 txindex;
        uint256 oindex;
    }

    function decodeInput(RLP.RLPItem memory encoded) internal pure returns (TxInput memory) {
        RLP.RLPItem[] memory input = encoded.toList();
        require(input.length == 3, "invalid input encoding");

        return TxInput({
            blknum: input[0].toUint(),
            txindex: input[1].toUint(),
            oindex: input[2].toUint()
        });
    }

    function toUtxoPos(TxInput memory _input) internal pure returns (uint256) {
        return _input.blknum * BLOCK_OFFSET + _input.txindex * TX_OFFSET + _input.oindex;
    }
}
