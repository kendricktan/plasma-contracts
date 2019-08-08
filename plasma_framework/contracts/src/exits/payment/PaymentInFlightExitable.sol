pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./PaymentExitDataModel.sol";
import "./spendingConditions/IPaymentSpendingCondition.sol";
import "./spendingConditions/PaymentSpendingConditionRegistry.sol";
import "../IStateTransitionVerifier.sol";
import "../utils/ExitId.sol";
import "../utils/ExitableTimestamp.sol";
import "../utils/OutputId.sol";
import "../../framework/PlasmaFramework.sol";
import "../../framework/interfaces/IExitProcessor.sol";
import "../../utils/Bits.sol";
import "../../utils/IsDeposit.sol";
import "../../utils/OnlyWithValue.sol";
import "../../utils/UtxoPosLib.sol";
import "../../utils/Merkle.sol";
import "../../transactions/PaymentTransactionModel.sol";
import "../../transactions/WireTransaction.sol";
import "../../transactions/outputs/PaymentOutputModel.sol";

contract PaymentInFlightExitable is
    IExitProcessor,
    OnlyWithValue,
    PaymentSpendingConditionRegistry
{
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    using IsDeposit for IsDeposit.Predicate;
    using PaymentOutputModel for PaymentOutputModel.Output;
    using RLP for bytes;
    using RLP for RLP.RLPItem;
    using UtxoPosLib for UtxoPosLib.UtxoPos;

    uint8 constant public MAX_INPUT_NUM = 4;
    uint256 public constant IN_FLIGHT_EXIT_BOND = 31415926535 wei;
    mapping (uint192 => PaymentExitDataModel.InFlightExit) public inFlightExits;

    PlasmaFramework private framework;
    IStateTransitionVerifier private transitionVerifier;
    IsDeposit.Predicate private isDeposit;
    ExitableTimestamp.Calculator private exitableTimestampCalculator;

    event InFlightExitStarted(
        address indexed initiator,
        bytes32 txHash
    );

    /**
    * @notice Wraps arguments for startInFlightExit.
    * @param inFlightTx RLP encoded in-flight transaction.
    * @param inputTxs Transactions that created the inputs to the in-flight transaction. In the same order as in-flight transaction inputs.
    * @param inputUtxosPos Utxos that represent in-flight transaction inputs. In the same order as input transactions.
    * @param inputUtxosTypes Output types of in flight transaction inputs. In the same order as input transactions.
    * @param inputTxsInclusionProofs Merkle proofs that show the input-creating transactions are valid. In the same order as input transactions.
    * @param inFlightTxWitnesses Witnesses for in-flight transaction. In the same order as input transactions.
    */
    struct StartExitArgs {
        bytes inFlightTx;
        bytes[] inputTxs;
        uint256[] inputUtxosPos;
        uint256[] inputUtxosTypes;
        bytes[] inputTxsInclusionProofs;
        bytes[] inFlightTxWitnesses;
    }

    /**
     * @dev data to be passed around start in-flight exit helper functions
     * @param exitId ID of the exit.
     * @param inFlightTxRaw In-flight transaction as bytes.
     * @param inFlightTx Decoded in-flight transaction.
     * @param inFlightTxHash Hash of in-flight transaction.
     * @param inputTxs Input transactions as bytes.
     * @param inputUtxosPos Postions of input utxos.
     * @param inputUtxosPos Postions of input utxos coded as integers.
     * @param inputUtxosTypes Types of outputs that make in-flight transaction inputs.
     * @param inputTxsInclusionProofs Merkle proofs for input transactions.
     * @param inFlightTxWitnesses Witnesses for in-flight transactions.
     * @param outputIds Output ids for input transactions.
     */
    struct StartExitData {
        uint192 exitId;
        bytes inFlightTxRaw;
        PaymentTransactionModel.Transaction inFlightTx;
        bytes32 inFlightTxHash;
        bytes[] inputTxs;
        UtxoPosLib.UtxoPos[] inputUtxosPos;
        uint256[] inputUtxosPosRaw;
        uint256[] inputUtxosTypes;
        bytes[] inputTxsInclusionProofs;
        bytes[] inFlightTxWitnesses;
        bytes32[] outputIds;
    }

    constructor(PlasmaFramework _framework, IStateTransitionVerifier _transitionVerifier) public {
        framework = _framework;
        transitionVerifier = _transitionVerifier;
        isDeposit = IsDeposit.Predicate(framework.CHILD_BLOCK_INTERVAL());
        exitableTimestampCalculator = ExitableTimestamp.Calculator(framework.minExitPeriod());
    }

    /**
     * @notice Starts withdrawal from a transaction that might be in-flight.
     * @dev requires the exiting UTXO's token to be added via 'addToken'
     * @dev Uses struct as input because too many variables and failed to compile.
     * @dev Uses public instead of external because ABIEncoder V2 does not support struct calldata + external
     * @param args input argument data to challenge. See struct 'StartExitArgs' for detailed info.
     */
    function startInFlightExit(StartExitArgs memory args) public payable onlyWithValue(IN_FLIGHT_EXIT_BOND) {
        StartExitData memory startExitData = createStartExitData(args);
        verifyStart(startExitData);
        startExit(startExitData);
        emit InFlightExitStarted(msg.sender, startExitData.inFlightTxHash);
    }

    function createStartExitData(StartExitArgs memory args) private view returns (StartExitData memory) {
        StartExitData memory exitData;
        exitData.exitId = ExitId.getInFlightExitId(args.inFlightTx);
        exitData.inFlightTxRaw = args.inFlightTx;
        exitData.inFlightTx = PaymentTransactionModel.decode(args.inFlightTx);
        exitData.inFlightTxHash = keccak256(args.inFlightTx);
        exitData.inputTxs = args.inputTxs;
        exitData.inputUtxosPos = decodeInputTxsPositions(args.inputUtxosPos);
        exitData.inputUtxosPosRaw = args.inputUtxosPos;
        exitData.inputUtxosTypes = args.inputUtxosTypes;
        exitData.inputTxsInclusionProofs = args.inputTxsInclusionProofs;
        exitData.inFlightTxWitnesses = args.inFlightTxWitnesses;
        exitData.outputIds = getOutputIds(exitData.inputTxs, exitData.inputUtxosPos);
        return exitData;
    }

    function decodeInputTxsPositions(uint256[] memory inputUtxosPos) private pure returns (UtxoPosLib.UtxoPos[] memory) {
        require(inputUtxosPos.length <= MAX_INPUT_NUM, "To many transactions provided");

        UtxoPosLib.UtxoPos[] memory utxosPos = new UtxoPosLib.UtxoPos[](inputUtxosPos.length);
        for (uint i = 0; i < inputUtxosPos.length; i++) {
            utxosPos[i] = UtxoPosLib.UtxoPos(inputUtxosPos[i]);
        }
        return utxosPos;
    }

    function getOutputIds(bytes[] memory inputTxs, UtxoPosLib.UtxoPos[] memory utxoPos) private view returns (bytes32[] memory) {
        require(inputTxs.length == utxoPos.length, "Number of input transactions does not match number of provided input utxos positions");
        bytes32[] memory outputIds = new bytes32[](inputTxs.length);
        for (uint i = 0; i < inputTxs.length; i++) {
            bool isDepositTx = isDeposit.test(utxoPos[i].blockNum());
            outputIds[i] = isDepositTx ?
                OutputId.computeDepositOutputId(inputTxs[i], utxoPos[i].outputIndex(), utxoPos[i].value)
                : OutputId.computeNormalOutputId(inputTxs[i], utxoPos[i].outputIndex());
        }
        return outputIds;
    }

    function verifyStart(StartExitData memory exitData) private view {
        verifyExitNotStarted(exitData.exitId);
        verifyNumberOfInputsMatchesNumberOfInFlightTransactionInputs(exitData);
        verifyNoInputSpentMoreThanOnce(exitData.inFlightTx);
        verifyInputTransactionsInludedInPlasma(exitData);
        verifyInputsSpent(exitData);
         require(
            transitionVerifier.isCorrectStateTransition(exitData.inFlightTxRaw, exitData.inputTxs, exitData.inputUtxosPosRaw),
            "Incorrect state transition"
        );
    }

    function verifyExitNotStarted(uint192 exitId) private view {
        PaymentExitDataModel.InFlightExit storage exit = inFlightExits[exitId];
        require(exit.exitStartTimestamp == 0, "There is an active in-flight exit from this transaction");
        require(!isFinalized(exit), "This in-flight exit has already been finalized");
    }

    function isFinalized(PaymentExitDataModel.InFlightExit storage ife) private view returns (bool) {
        return Bits.bitSet(ife.exitMap, 255);
    }

    function verifyNumberOfInputsMatchesNumberOfInFlightTransactionInputs(StartExitData memory exitData) private pure {
        require(
            exitData.inputUtxosPos.length == exitData.inFlightTx.inputs.length,
            "Number of input transactions positions does not match number of in-flight transaction inputs"
        );
        require(
            exitData.inputUtxosTypes.length == exitData.inFlightTx.inputs.length,
            "Number of input utxo types does not match number of in-flight transaction inputs"
        );
        require(
            exitData.inputTxsInclusionProofs.length == exitData.inFlightTx.inputs.length,
            "Number of input transactions inclusion proofs does not match number of in-flight transaction inputs"
        );
        require(
            exitData.inFlightTxWitnesses.length == exitData.inFlightTx.inputs.length,
            "Number of input transactions witnesses does not match number of in-flight transaction inputs"
        );
    }

    function verifyNoInputSpentMoreThanOnce(PaymentTransactionModel.Transaction memory inFlightTx) private pure {
        if (inFlightTx.inputs.length > 1) {
            for (uint i = 0; i < inFlightTx.inputs.length; i++) {
                for (uint j = i + 1; j < inFlightTx.inputs.length; j++) {
                    require(inFlightTx.inputs[i] != inFlightTx.inputs[j], "In-flight transaction must have unique inputs");
                }
            }
        }
    }

    function verifyInputTransactionsInludedInPlasma(StartExitData memory exitData) private view {
        for (uint i = 0; i < exitData.inputTxs.length; i++) {
            (bytes32 root, ) = framework.blocks(exitData.inputUtxosPos[i].blockNum());
            bytes32 leaf = keccak256(exitData.inputTxs[i]);
            require(
                Merkle.checkMembership(leaf, exitData.inputUtxosPos[i].txIndex(), root, exitData.inputTxsInclusionProofs[i]),
                "Input transaction is not included in plasma"
            );
        }
    }

    function verifyInputsSpent(StartExitData memory exitData) private view {
        for (uint i = 0; i < exitData.inputTxs.length; i++) {
            uint16 outputIndex = exitData.inputUtxosPos[i].outputIndex();
            WireTransaction.Output memory output = WireTransaction.getOutput(exitData.inputTxs[i], outputIndex);

            //FIXME: consider moving spending conditions to PlasmaFramework
            IPaymentSpendingCondition condition = PaymentSpendingConditionRegistry.spendingConditions(
                exitData.inputUtxosTypes[i], exitData.inFlightTx.txType);
            require(address(condition) != address(0), "Spending condition contract not found");

            bool isSpentByInFlightTx = condition.verify(
                output.outputGuard,
                exitData.inputUtxosPos[i].value,
                exitData.outputIds[i],
                exitData.inFlightTxRaw,
                uint8(i),
                exitData.inFlightTxWitnesses[i]
            );
            require(isSpentByInFlightTx, "Spending condition failed");
        }
    }

    function startExit(StartExitData memory startExitData) private {
        PaymentExitDataModel.InFlightExit storage ife = inFlightExits[startExitData.exitId];
        ife.bondOwner = msg.sender;
        ife.position = getYoungestInputUtxoPosition(startExitData.inputUtxosPos);
        ife.exitStartTimestamp = block.timestamp;
        setInFlightExitInputs(ife, startExitData);
        //TODO: I am not sure if we need that, outputIds for ife outputs can be calculated on piggybacks
        setInFlightExitOutputs(ife, startExitData);
    }

    function getYoungestInputUtxoPosition(UtxoPosLib.UtxoPos[] memory inputUtxosPos) private pure returns (uint256) {
        uint256 youngest = inputUtxosPos[0].value;
        for (uint i = 1; i < inputUtxosPos.length; i++) {
            if (inputUtxosPos[i].value > youngest) {
                youngest = inputUtxosPos[i].value;
            }
        }
        return youngest;
    }

    function setInFlightExitInputs(
        PaymentExitDataModel.InFlightExit storage ife,
        StartExitData memory exitData
    )
        private
    {
        for (uint i = 0; i < exitData.inputTxs.length; i++) {
            uint16 outputIndex = exitData.inputUtxosPos[i].outputIndex();
            WireTransaction.Output memory output = WireTransaction.getOutput(exitData.inputTxs[i], outputIndex);

            ife.inputs[i] = PaymentExitDataModel.WithdrawData(
                output.outputGuard,
                exitData.outputIds[i],
                output.token,
                output.amount
            );
        }
    }

    function setInFlightExitOutputs(
        PaymentExitDataModel.InFlightExit storage ife,
        StartExitData memory exitData
    )
        private
    {
        for (uint i = 0; i < exitData.inFlightTx.outputs.length; i++) {
            bytes32 outputId = OutputId.computeNormalOutputId(exitData.inFlightTxRaw, i);
            PaymentOutputModel.Output memory output = exitData.inFlightTx.outputs[i];

            ife.inputs[i] = PaymentExitDataModel.WithdrawData(
                output.outputGuard,
                outputId,
                output.token,
                output.amount
            );
        }
    }
}
