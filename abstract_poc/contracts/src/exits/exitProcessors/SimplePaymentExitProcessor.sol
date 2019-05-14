pragma solidity ^0.5.0;
// Should be safe to use. It is marked as experimental as it costs higher gas usage.
// see: https://github.com/ethereum/solidity/issues/5397
pragma experimental ABIEncoderV2;

import "./BaseExitProcessor.sol";
import "../models/SimplePaymentExitDataModel.sol";

contract SimplePaymentExitProcessor is BaseExitProcessor {
    constructor(address _framework, uint256 _txType)
        BaseExitProcessor(_framework, _txType) public {}

    function processExit(uint256 _exitId) external onlyFromFramework {
        bytes memory exitDataInBytes = framework.getBytesStorage(txType, bytes32(_exitId));
        SimplePaymentExitDataModel.Data memory exitData = abi.decode(exitDataInBytes, (SimplePaymentExitDataModel.Data));

        if (exitData.exitable) {
            framework.withdraw(exitData.exitTarget, exitData.amount);
        }
    }

}