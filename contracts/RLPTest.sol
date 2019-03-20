pragma solidity ^0.4.0;

import "./RLPDecode.sol";


/**
 * @title RLPTest
 * @dev Contract for testing RLP decoding.
 */
contract RLPTest {
    function eight(bytes tx_bytes)
        public
        view
        returns (uint256, address, address)
    {
        var txList = RLPDecode.toList(RLPDecode.toRLPItem(tx_bytes));
        return (
            RLPDecode.toUint(txList[5]),
            RLPDecode.toAddress(txList[6]),
            RLPDecode.toAddress(txList[7])
        );
    }

    function eleven(bytes tx_bytes)
        public
        view
        returns (uint256, address, address, address)
    {
        var txList = RLPDecode.toList(RLPDecode.toRLPItem(tx_bytes));
        return (
            RLPDecode.toUint(txList[7]),
            RLPDecode.toAddress(txList[8]),
            RLPDecode.toAddress(txList[9]),
            RLPDecode.toAddress(txList[10])
        );
    }
}
