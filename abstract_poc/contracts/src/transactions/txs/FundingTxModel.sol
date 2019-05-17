pragma solidity ^0.5.0;

import "../TxInputModel.sol";
import "../outputs/PaymentOutputModel.sol";
import "../outputs/DexOutputModel.sol";

library FundingTxModel {
    uint256 constant TX_TYPE = 2;

    using DexOutputModel for DexOutputModel.TxOutput;
    using PaymentOutputModel for PaymentOutputModel.TxOutput;

    struct ProofData {
        bytes signature;
    }

    struct MetaData {
        bytes32 data;
    }

    struct Tx {
        uint256 txType;
        TxInputModel.TxInput[1] inputs;
        DexOutputModel.TxOutput[1] dexOutputs;
        ProofData proofData;
        MetaData metaData;
    }

    function getTxType() internal pure returns (uint256) {
        return TX_TYPE;
    }
}


// temp code for POC testing
library DummyTxFactory {
    function get() internal pure returns (FundingTxModel.Tx memory) {
        // dummy implement
        TxInputModel.TxInput[1] memory ins;
        DexOutputModel.TxOutput[1] memory dexOutputs;

        TxInputModel.TxInput memory dummyTxIn = TxInputModel.TxInput(1, 0, 0);
        DexOutputModel.TxOutput memory dummyDexOutput = DexOutputModel.TxOutput(
            1, DexOutputModel.TxOutputData(10, address(0), address(0), address(0)));

        ins[0] = dummyTxIn;
        dexOutputs[0] = dummyDexOutput;

        return FundingTxModel.Tx(
            FundingTxModel.getTxType(),
            ins,
            dexOutputs,
            FundingTxModel.ProofData(bytes("signature")), FundingTxModel.MetaData("")
        );
    }
}