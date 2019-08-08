pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./PaymentInFlightExitRouterArgs.sol";
import "../PaymentExitDataModel.sol";
import "../controllers/PaymentStartInFlightExit.sol";
import "../controllers/PaymentPiggybackInFlightExitOnInput.sol";
import "../controllers/PaymentPiggybackInFlightExitOnOutput.sol";
import "../spendingConditions/PaymentSpendingConditionRegistry.sol";
import "../../OutputGuardParserRegistry.sol";
import "../../../utils/OnlyWithValue.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../framework/interfaces/IExitProcessor.sol";

contract PaymentInFlightExitRouter is IExitProcessor, OnlyWithValue {
    using PaymentStartInFlightExit for PaymentStartInFlightExit.Controller;
    using PaymentPiggybackInFlightExitOnInput for PaymentPiggybackInFlightExitOnInput.Controller;
    using PaymentPiggybackInFlightExitOnOutput for PaymentPiggybackInFlightExitOnOutput.Controller;

    uint256 public constant IN_FLIGHT_EXIT_BOND = 31415926535 wei;
    uint256 public constant PIGGYBACK_BOND = 31415926535 wei;

    PaymentExitDataModel.InFlightExitMap inFlightExitMap;
    PaymentStartInFlightExit.Controller startInFlightExitController;
    PaymentPiggybackInFlightExitOnInput.Controller piggybackInFlightExitOnInputController;
    PaymentPiggybackInFlightExitOnOutput.Controller piggybackInFlightExitOnOutputController;

    constructor(
        PlasmaFramework framework,
        OutputGuardParserRegistry outputGuardRegistry,
        PaymentSpendingConditionRegistry spendingConditionRegistry
    )
        public
    {
        startInFlightExitController = PaymentStartInFlightExit.buildController(
            framework, spendingConditionRegistry
        );

        piggybackInFlightExitOnInputController = PaymentPiggybackInFlightExitOnInput.buildController(
            framework, this
        );

        piggybackInFlightExitOnOutputController = PaymentPiggybackInFlightExitOnOutput.buildController(
            framework, this, outputGuardRegistry
        );
    }

    function inFlightExits(uint192 _exitId) public view returns (PaymentExitDataModel.InFlightExit memory) {
        return inFlightExitMap.exits[_exitId];
    }

    /**
     * @notice Starts withdrawal from a transaction that might be in-flight.
     * @param args input argument data to challenge. See struct 'StartExitArgs' for detailed info.
     */
    function startInFlightExit(PaymentInFlightExitRouterArgs.StartExitArgs memory args)
        public
        payable
        onlyWithValue(IN_FLIGHT_EXIT_BOND)
    {
        startInFlightExitController.run(inFlightExitMap, args);
    }

    /**
     * @notice Piggyback on an in-flight exiting tx input. Would be processed if the in-flight exit is non-canonical.
     * @param args input argument data to piggyback. See struct 'PiggybackInFlightExitOnInputArgs' for detailed info.
     */
    function piggybackInFlightExitOnInput(
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnInputArgs memory args
    )
        public
        payable
        onlyWithValue(PIGGYBACK_BOND)
    {
        piggybackInFlightExitOnInputController.run(inFlightExitMap, args);
    }

    /**
     * @notice Piggyback on an in-flight exiting tx output. Would be processed if the in-flight exit is canonical.
     * @param args input argument data to piggyback. See struct 'PiggybackInFlightExitOnOutputArgs' for detailed info.
     */
    function piggybackInFlightExitOnOutput(
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnOutputArgs memory args
    )
        public
        payable
        onlyWithValue(PIGGYBACK_BOND)
    {
        piggybackInFlightExitOnOutputController.run(inFlightExitMap, args);
    }
}
