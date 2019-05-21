pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

library PaymentOutputModel {
    uint256 constant OUTPUT_TYPE = 1;

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
}

// temp code for POC testing
library DummyPaymentOutputFactory {
    function get() internal pure returns (PaymentOutputModel.TxOutput memory) {
        // dummy implement
        return PaymentOutputModel.TxOutput(1, PaymentOutputModel.TxOutputData(10, address(0), address(0)));
    }
}