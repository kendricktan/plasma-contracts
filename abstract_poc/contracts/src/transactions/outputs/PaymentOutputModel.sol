pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../../utils/RLP.sol";

library PaymentOutputModel {
    uint256 constant OUTPUT_TYPE = 1;

    using RLP for bytes;
    using RLP for RLP.RLPItem;

    struct TxOutputData {
        uint256 amount;
        address owner;
        address token;
    }

    struct TxOutput {
        uint256 outputType;
        TxOutputData outputData;
    }

    function getOutputType() public pure returns (uint256) {
        return OUTPUT_TYPE;
    }

    function checkFormat(TxOutput memory _output) internal pure returns (bool, string memory) {
        if (_output.outputType != OUTPUT_TYPE) {
            return (false, "Payment output needs to be type 1");
        }

        return (true, "");
    }

    function hash(TxOutput memory _output) internal pure returns (bytes32) {
        return keccak256(abi.encode(_output));
    }

    function decodeOutput(RLP.RLPItem memory encoded) internal pure returns (TxOutput memory) {
      RLP.RLPItem[] memory output = encoded.toList();
      require(output.length == 2, "invalid output encoding");

      uint256 outputType = output[0].toUint();

      RLP.RLPItem[] memory outputDataRLP = output[1].toList();
      require(outputDataRLP.length == 3);
      TxOutputData memory outputData = TxOutputData({
        amount: outputDataRLP[0].toUint(),
        owner: outputDataRLP[1].toAddress(),
        token: outputDataRLP[2].toAddress()
      });

      return TxOutput(outputType, outputData);
    }
}
