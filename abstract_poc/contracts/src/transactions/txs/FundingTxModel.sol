pragma solidity ^0.5.0;

import "../TxInputModel.sol";
import "../outputs/PaymentOutputModel.sol";
import "../outputs/DexOutputModel.sol";

library FundingTxModel {
    uint256 constant TX_TYPE = 2;

    using DexOutputModel for DexOutputModel.TxOutput;
    using PaymentOutputModel for PaymentOutputModel.TxOutput;

    struct Witness {
        bytes signature;
    }

    struct MetaData {
        bytes32 data;
    }

    struct Tx {
        uint256 txType;
        TxInputModel.TxInput[1] inputs;
        DexOutputModel.TxOutput[1] dexOutputs;
        Witness[1] witnesses;
        MetaData metaData;
    }

    function getTxType() internal pure returns (uint256) {
        return TX_TYPE;
    }

    function decode(bytes memory _tx) internal pure returns (FundingTxModel.Tx memory){
        // POC implement
        return DummyFundingTxFactory.get();
    }
}


// temp code for POC testing
library DummyFundingTxFactory {
    function get() internal pure returns (FundingTxModel.Tx memory) {
        // dummy implement
        TxInputModel.TxInput[1] memory ins;
        DexOutputModel.TxOutput[1] memory dexOutputs;
        FundingTxModel.Witness[1] memory witnesses;

        TxInputModel.TxInput memory dummyTxIn = TxInputModel.TxInput(1, 0, 0);
        DexOutputModel.TxOutput memory dummyDexOutput = DexOutputModel.TxOutput(
            1, DexOutputModel.TxOutputData(10, address(0), address(0), address(0)));

        ins[0] = dummyTxIn;
        dexOutputs[0] = dummyDexOutput;
        witnesses[0] = FundingTxModel.Witness(bytes("signature"));
        return FundingTxModel.Tx(
            FundingTxModel.getTxType(),
            ins,
            dexOutputs,
            witnesses,
            FundingTxModel.MetaData("")
        );
    }
}
