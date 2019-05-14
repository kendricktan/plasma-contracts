pragma solidity ^0.5.0;

import "../TxInputModel.sol";
import {TxOutputModel as PaymentOutput} from "../outputs/PaymentOutputModel.sol";
import {TxOutputModel as DexOutput} from "../outputs/DexOutputModel.sol";

library TxModel {
    uint256 constant TX_TYPE = 2;

    using DexOutput for DexOutput.TxOutput;
    using PaymentOutput for PaymentOutput.TxOutput;

    struct ProofData {
        bytes signature;
    }

    struct MetaData {
        bytes32 data;
    }

    struct Tx {
        uint256 txType;
        TxInputModel.TxInput[1] inputs;
        DexOutput.TxOutput[1] dexOutputs;
        ProofData proofData;
        MetaData metaData;
    }

    function getTxType() internal pure returns (uint256) {
        return TX_TYPE;
    }
}


// temp code for POC testing
library DummyTxFactory {
    function get() internal pure returns (TxModel.Tx memory) {
        // dummy implement
        TxInputModel.TxInput[1] memory ins;
        DexOutput.TxOutput[1] memory dexOutputs;

        TxInputModel.TxInput memory dummyTxIn = TxInputModel.TxInput(1, 0, 0);
        DexOutput.TxOutput memory dummyDexOutput = DexOutput.TxOutput(
            1, DexOutput.TxOutputData(10, address(0), address(0), address(0)));

        ins[0] = dummyTxIn;
        dexOutputs[0] = dummyDexOutput;

        return TxModel.Tx(TxModel.getTxType(), ins, dexOutputs, TxModel.ProofData(bytes("signature")), TxModel.MetaData(""));
    }
}