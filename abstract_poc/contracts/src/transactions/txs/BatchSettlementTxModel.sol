pragma solidity ^0.5.0;

import "../TxInputModel.sol";
import {TxOutputModel as PaymentOutput} from "../outputs/PaymentOutputModel.sol";
import {TxOutputModel as DexOutput} from "../outputs/DexOutputModel.sol";

library TxModel {
    uint256 constant TX_TYPE = 3;

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
        TxInputModel.TxInput[] inputs;
        DexOutput.TxOutput[] dexOutputs;
        PaymentOutput.TxOutput[] paymentOutputs;
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
        TxInputModel.TxInput[] memory ins = new TxInputModel.TxInput[](1);
        DexOutput.TxOutput[] memory dexOutputs = new DexOutput.TxOutput[](1);
        PaymentOutput.TxOutput[] memory paymentOutputs;

        TxInputModel.TxInput memory dummyTxIn = TxInputModel.TxInput(0, 0, 0);
        DexOutput.TxOutput memory dummyDexOutput = DexOutput.TxOutput(
            1, DexOutput.TxOutputData(10, address(0), address(0), address(0)));
        PaymentOutput.TxOutput memory dummyPaymentOutput = PaymentOutput.TxOutput(
            1, PaymentOutput.TxOutputData(10, address(0), address(0)));

        ins[0] = dummyTxIn;
        dexOutputs[0] = dummyDexOutput;
        paymentOutputs[0] = dummyPaymentOutput;

        return TxModel.Tx(TxModel.getTxType(), ins, dexOutputs, paymentOutputs, TxModel.ProofData(bytes("signature")), TxModel.MetaData(""));
    }
}