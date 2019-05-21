pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

library DexOutputModel {
    uint256 constant OUTPUT_TYPE = 2;

    struct TxOutputData {
        uint256 amount;
        address owner;
        address venue;
        address token;
    }

    struct TxOutput {
        uint256 outputType;
        TxOutputData outputData;
    }

    function checkFormat(TxOutput memory _output) internal pure returns (bool, string memory) {
        if (_output.outputType != OUTPUT_TYPE) {
            return (false, "Dex output needs to be type 1");
        }

        return (true, "");
    }

    function hash(TxOutput memory _output) internal pure returns (bytes32) {
        return keccak256(abi.encode(_output));
    }

    function getOutputType() internal pure returns (uint256) {
        return OUTPUT_TYPE;
    }
}

// temp code for POC testing
library DummyDexOutputFactory {
    function get() internal pure returns (DexOutputModel.TxOutput memory) {
        // dummy implement
        return DexOutputModel.TxOutput(1, DexOutputModel.TxOutputData(10, address(0), address(0), address(0)));
    }
}