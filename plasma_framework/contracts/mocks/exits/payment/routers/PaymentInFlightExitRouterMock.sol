pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../../../../src/exits/payment/PaymentExitDataModel.sol";
import "../../../../src/exits/payment/routers/PaymentInFlightExitRouter.sol";
import "../../../../src/framework/PlasmaFramework.sol";

contract PaymentInFlightExitRouterMock is PaymentInFlightExitRouter {
    constructor(
        PlasmaFramework framework,
        OutputGuardParserRegistry outputGuardParserRegistry,
        PaymentSpendingConditionRegistry spendingConditionRegistry
    )
        public
        PaymentInFlightExitRouter(framework, outputGuardParserRegistry, spendingConditionRegistry) {
    }

    // to override IExitProcessor function
    function processExit(uint192 exitId) external {}

    function finalizeExit(uint192 exitId) public {
        inFlightExitMap.exits[exitId].exitStartTimestamp = 1;
        inFlightExitMap.exits[exitId].exitMap = Bits.setBit(inFlightExitMap.exits[exitId].exitMap, 255);
    }

    function setInFlightExit(uint192 exitId, PaymentExitDataModel.InFlightExit memory exit) public {
        PaymentExitDataModel.InFlightExit storage ife = inFlightExitMap.exits[exitId];
        ife.exitStartTimestamp = exit.exitStartTimestamp;
        ife.exitMap = exit.exitMap;
        ife.position = exit.position;
        ife.bondOwner = exit.bondOwner;
        ife.oldestCompetitorPosition = exit.oldestCompetitorPosition;

        for(uint i = 0 ; i < exit.inputs.length; i++) {
            ife.inputs[i] = exit.inputs[i];
        }

        for(uint i = 0 ; i < exit.outputs.length; i++) {
            ife.outputs[i] = exit.outputs[i];
        }
    }

    function getInFlightExitInput(uint192 exitId, uint8 inputIndex) public view returns (PaymentExitDataModel.WithdrawData memory) {
        return inFlightExitMap.exits[exitId].inputs[inputIndex];
    }

    function getInFlightExitOutput(uint192 exitId, uint8 outputIndex) public view returns (PaymentExitDataModel.WithdrawData memory) {
        return inFlightExitMap.exits[exitId].outputs[outputIndex];
    }
}
