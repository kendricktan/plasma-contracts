pragma solidity ^0.5.0;

import "../TxInputModel.sol";
import "../outputs/PaymentOutputModel.sol";
import "../outputs/DexOutputModel.sol";

library BatchSettlementTxModel {
    uint256 constant TX_TYPE = 3;

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
        TxInputModel.TxInput[] inputs;
        DexOutputModel.TxOutput[] dexOutputs;
        PaymentOutputModel.TxOutput[] paymentOutputs;
        ProofData proofData;
        MetaData metaData;
    }

    function getTxType() internal pure returns (uint256) {
        return TX_TYPE;
    }
}


// temp code for POC testing
library DummyTxFactory {
    function get() internal pure returns (BatchSettlementTxModel.Tx memory) {
        // dummy implement
        TxInputModel.TxInput[] memory ins = new TxInputModel.TxInput[](1);
        DexOutputModel.TxOutput[] memory dexOutputs = new DexOutputModel.TxOutput[](1);
        PaymentOutputModel.TxOutput[] memory paymentOutputs;

        TxInputModel.TxInput memory dummyTxIn = TxInputModel.TxInput(0, 0, 0);
        DexOutputModel.TxOutput memory dummyDexOutput = DexOutputModel.TxOutput(
            1, DexOutputModel.TxOutputData(10, address(0), address(0), address(0)));
        PaymentOutputModel.TxOutput memory dummyPaymentOutput = PaymentOutputModel.TxOutput(
            1, PaymentOutputModel.TxOutputData(10, address(0), address(0)));

        ins[0] = dummyTxIn;
        dexOutputs[0] = dummyDexOutput;
        paymentOutputs[0] = dummyPaymentOutput;

        return BatchSettlementTxModel.Tx(
            BatchSettlementTxModel.getTxType(),
            ins,
            dexOutputs,
            paymentOutputs,
            BatchSettlementTxModel.ProofData(bytes("signature")), BatchSettlementTxModel.MetaData("")
        );
    }
}