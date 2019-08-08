pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../routers/PaymentInFlightExitRouterArgs.sol";
import "../../utils/ExitableTimestamp.sol";
import "../../utils/ExitId.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../framework/interfaces/IExitProcessor.sol";
import "../../../utils/IsDeposit.sol";
import "../../../utils/UtxoPosLib.sol";

library PaymentPiggybackInFlightExitOnInput {
    using UtxoPosLib for UtxoPosLib.UtxoPos;
    using IsDeposit for IsDeposit.Predicate;
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    using PaymentExitDataModel for PaymentExitDataModel.InFlightExit;

    uint8 constant public MAX_INPUT_NUM = 4;
    uint8 constant public MAX_OUTPUT_NUM = 4;

    struct Controller {
        PlasmaFramework framework;
        IsDeposit.Predicate isDeposit;
        ExitableTimestamp.Calculator exitableTimestampCalculator;
        IExitProcessor exitProcessor;
        uint256 minExitPeriod;
    }

    event InFlightExitInputPiggybacked(
        address indexed owner,
        bytes32 txHash,
        uint16 inputIndex
    );

    function buildController(PlasmaFramework framework, IExitProcessor exitProcessor)
        public
        view
        returns (Controller memory)
    {
        return Controller({
            framework: framework,
            isDeposit: IsDeposit.Predicate(framework.CHILD_BLOCK_INTERVAL()),
            exitableTimestampCalculator: ExitableTimestamp.Calculator(framework.minExitPeriod()),
            exitProcessor: exitProcessor,
            minExitPeriod: framework.minExitPeriod()
        });
    }

    function run(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnInputArgs memory args
    )
        public
    {
        require(args.inputIndex < MAX_INPUT_NUM, "Index exceed max size of tx input");

        uint192 exitId = ExitId.getInFlightExitId(args.inFlightTx);
        PaymentExitDataModel.InFlightExit storage exit = inFlightExitMap.exits[exitId];

        require(exit.exitStartTimestamp != 0, "No in-flight exit to piggyback on");
        require(exit.isInFirstPhase(self.minExitPeriod), "Can only piggyback in first phase of exit period");
        require(!exit.isInputPiggybacked(args.inputIndex), "The indexed input has been piggybacked already");

        PaymentExitDataModel.WithdrawData memory withdrawData = exit.inputs[args.inputIndex];
        require(withdrawData.exitTarget == msg.sender, "Can be called by the exit target of input only");

        if (exit.isFirstPiggybackOfTheToken(withdrawData.token)) {
            enqueue(self, withdrawData.token, UtxoPosLib.UtxoPos(exit.position), exitId);
        }

        exit.setInputPiggybacked(args.inputIndex);

        emit InFlightExitInputPiggybacked(msg.sender, keccak256(args.inFlightTx), args.inputIndex);
    }

    function enqueue(
        Controller memory controller,
        address token,
        UtxoPosLib.UtxoPos memory utxoPos,
        uint192 exitId
    )
        private
    {
        (, uint256 blockTimestamp) = controller.framework.blocks(utxoPos.blockNum());
        bool isPositionDeposit = controller.isDeposit.test(utxoPos.blockNum());
        uint64 exitableAt = controller.exitableTimestampCalculator.calculate(now, blockTimestamp, isPositionDeposit);

        controller.framework.enqueue(token, exitableAt, utxoPos.txPos(), exitId, controller.exitProcessor);
    }
}
