pragma solidity ^0.5.0;

import "../TxInputModel.sol";
import "../outputs/PaymentOutputModel.sol";
import "../../utils/RLP.sol";

library SimplePaymentTxModel {
    uint256 constant TX_TYPE = 1;
    uint256 constant MAX_INPUT = 1;
    uint256 constant MAX_OUPUT = 1;

    using PaymentOutputModel for PaymentOutputModel.TxOutput;
    using PaymentOutputModel for RLP.RLPItem;
    using TxInputModel for RLP.RLPItem;
    using RLP for bytes;
    using RLP for RLP.RLPItem;

    struct Witness {
        bytes signature;
    }

    struct MetaData {
        bytes32 data;
    }

    struct Tx {
        uint256 txType;
        TxInputModel.TxInput[MAX_INPUT] inputs;
        PaymentOutputModel.TxOutput[MAX_OUPUT] outputs;
        MetaData metaData;
    }

    function getTxType() internal pure returns (uint256) {
        return TX_TYPE;
    }

    function checkFormat(Tx memory _tx) internal pure returns (bool, string memory) {
        if (_tx.txType != TX_TYPE) {
            return (false, "Simple MoreVP tx needs to be tx type 1");
        }

        for (uint i = 0 ; i < MAX_OUPUT; i++) {
            (bool result, string memory message) = _tx.outputs[i].checkFormat();
            if (result == false) {
                return (result, message);
            }
        }

        return (true, "");
    }

    function decode(bytes memory _tx) internal view returns (SimplePaymentTxModel.Tx memory) {
      RLP.RLPItem[] memory rlpTx = _tx.toRLPItem().toList();
      require(rlpTx.length == 4 || rlpTx.length == 3, "Invalid encoding of transaction");

      uint256 txType = rlpTx[0].toUint();
      RLP.RLPItem[] memory inputs = rlpTx[1].toList();
      RLP.RLPItem[] memory outputs = rlpTx[2].toList();

      require(inputs.length == 1, "Too many inputs");
      require(outputs.length == 1, "Too many outputs");

      SimplePaymentTxModel.Tx memory decodedTx;
      decodedTx.txType = txType;
      TxInputModel.TxInput memory input = inputs[0].decodeInput();
      decodedTx.inputs[0] = input;

      PaymentOutputModel.TxOutput memory output = outputs[0].decodeOutput();
      decodedTx.outputs[0] = output;

      if (rlpTx.length == 4) {
          decodedTx.metaData = MetaData(rlpTx[3].toBytes32());
      } else {
          decodedTx.metaData = MetaData("");
      }

      return decodedTx;
    }

    function decodeWitness(bytes memory _witness) internal view returns (Witness memory) {
      bytes memory witness = _witness.toRLPItem().toBytes();
      return Witness(_witness);
    }
}
