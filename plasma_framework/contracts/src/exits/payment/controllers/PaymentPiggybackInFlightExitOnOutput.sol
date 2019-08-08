pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../routers/PaymentInFlightExitRouterArgs.sol";
import "../../IOutputGuardParser.sol";
import "../../OutputGuardParserRegistry.sol";
import "../../utils/ExitableTimestamp.sol";
import "../../utils/ExitId.sol";
import "../../utils/OutputGuard.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../framework/interfaces/IExitProcessor.sol";
import "../../../transactions/outputs/PaymentOutputModel.sol";
import "../../../utils/IsDeposit.sol";
import "../../../utils/UtxoPosLib.sol";

library PaymentPiggybackInFlightExitOnOutput {
    using UtxoPosLib for UtxoPosLib.UtxoPos;
    using IsDeposit for IsDeposit.Predicate;
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    using PaymentExitDataModel for PaymentExitDataModel.InFlightExit;
    using PaymentOutputModel for PaymentOutputModel.Output;

    uint8 constant public MAX_INPUT_NUM = 4;
    uint8 constant public MAX_OUTPUT_NUM = 4;

    struct Controller {
        PlasmaFramework framework;
        IsDeposit.Predicate isDeposit;
        ExitableTimestamp.Calculator exitableTimestampCalculator;
        IExitProcessor exitProcessor;
        OutputGuardParserRegistry outputGuardParserRegistry;
        uint256 minExitPeriod;
    }

    event InFlightExitOutputPiggybacked(
        address indexed owner,
        bytes32 txHash,
        uint16 inputIndex
    );

    function buildController(
        PlasmaFramework framework,
        IExitProcessor exitProcessor,
        OutputGuardParserRegistry outputGuardParserRegistry
    )
        public
        view
        returns (Controller memory)
    {
        return Controller({
            framework: framework,
            isDeposit: IsDeposit.Predicate(framework.CHILD_BLOCK_INTERVAL()),
            exitableTimestampCalculator: ExitableTimestamp.Calculator(framework.minExitPeriod()),
            exitProcessor: exitProcessor,
            outputGuardParserRegistry: outputGuardParserRegistry,
            minExitPeriod: framework.minExitPeriod()
        });
    }

    function run(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnOutputArgs memory args
    )
        public
    {
        require(args.outputIndex < MAX_OUTPUT_NUM, "Index exceed max size of tx output");

        uint192 exitId = ExitId.getInFlightExitId(args.inFlightTx);
        PaymentExitDataModel.InFlightExit storage exit = inFlightExitMap.exits[exitId];

        require(exit.exitStartTimestamp != 0, "No inflight exit to piggyback on");
        require(exit.isInFirstPhase(self.minExitPeriod), "Can only piggyback in first phase of exit period");
        require(!exit.isOutputPiggybacked(args.outputIndex), "The output has been piggybacked already");

        PaymentOutputModel.Output memory output = PaymentTransactionModel.decode(args.inFlightTx).outputs[args.outputIndex];
        address payable exitTarget = getExitTargetOfOutput(self, output, args.outputType, args.outputGuardData);
        require(exitTarget == msg.sender, "Can be called by the exit target of output only");

        if (exit.isFirstPiggybackOfTheToken(output.token)) {
            enqueue(self, output.token, UtxoPosLib.UtxoPos(exit.position), exitId);
        }

        // output of exit data is set on piggyback insetad of startInFlightExit to save some gas as output is always together with tx
        PaymentExitDataModel.WithdrawData memory withdrawData = PaymentExitDataModel.WithdrawData(
            exitTarget, output.token, output.amount
        );

        exit.setOutputWithdrawData(withdrawData, args.outputIndex);
        exit.setOutputPiggybacked(args.outputIndex);

        emit InFlightExitOutputPiggybacked(msg.sender, keccak256(args.inFlightTx), args.outputIndex);
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

    function getExitTargetOfOutput(
        Controller memory controller,
        PaymentOutputModel.Output memory output,
        uint256 outputType,
        bytes memory outputGuardData
    )
        private
        view
        returns (address payable)
    {
        if (outputType == 0) {
            return output.owner();
        }

        require(
            OutputGuard.build(outputType, outputGuardData) == output.outputGuard,
            "Output guard data and output type from args mismatch with the outputguard in output"
        );

        IOutputGuardParser outputGuardParser = controller.outputGuardParserRegistry
                                                        .outputGuardParsers(outputType);

        require(
            address(outputGuardParser) != address(0),
            "Does not have outputGuardParser for the output type"
        );

        return outputGuardParser.parseExitTarget(outputGuardData);
    }
}
