pragma solidity ^0.5.0;

import "./RLP.sol";

contract RLPTest {

    using RLP for bytes;
    using RLP for RLP.RLPItem;

    function decodeList(bytes calldata _data) external {
      RLP.RLPItem memory item = _data.toRLPItem();
    }

    function decodeBytes(bytes calldata _data) external {
      RLP.RLPItem[] memory items = _data.toRLPItem().toList();
      bytes memory decoded1 = items[0].toBytes();
      bytes32 decoded2 = items[1].toBytes32();
    }

}
