pragma solidity ^0.5.0;

import '../../transactions/outputs/PaymentOutputModel.sol';
import '../../transactions/PaymentTransactionModel.sol';
import "../../utils/Bits.sol";

library PaymentExitDataModel {
    using Bits for uint256;

    uint8 constant public MAX_INPUT_NUM = 4;
    uint8 constant public MAX_OUTPUT_NUM = 4;

    struct StandardExit {
        bool exitable;
        uint192 utxoPos;
        bytes32 outputId;
        // Hash of output type and output guard.
        // Correctness of them would be checked when exit starts.
        // For other steps, they just check data consistency of input args.
        bytes32 outputTypeAndGuardHash;
        address token;
        address payable exitTarget;
        uint256 amount;
    }

    struct StandardExitMap {
        mapping (uint192 => PaymentExitDataModel.StandardExit) exits;
    }

    struct WithdrawData {
        address payable exitTarget;
        address token;
        uint256 amount;
    }

    struct InFlightExit {
        uint256 exitStartTimestamp;

        /**
         * exit map stores piggybacks and finalized exits
         * bit 255 is set only when in-flight exit has finalized
         * right most 0 ~ MAX_INPUT bits is flagged when input is piggybacked
         * right most MAX_INPUT ~ MAX_INPUT + MAX_OUTPUT bits is flagged when output is piggybacked
         */
        uint256 exitMap;
        uint256 position;
        WithdrawData[MAX_INPUT_NUM] inputs;
        WithdrawData[MAX_OUTPUT_NUM] outputs;
        address payable bondOwner;
        uint256 oldestCompetitorPosition;
    }

    struct InFlightExitMap {
        mapping (uint192 => PaymentExitDataModel.InFlightExit) exits;
    }

    function setInputPiggybacked(InFlightExit storage ife, uint16 index)
        internal
    {
        ife.exitMap = ife.exitMap.setBit(uint8(index));
    }

    function setOutputPiggybacked(InFlightExit storage ife, uint16 index)
        internal
    {
        uint8 indexInExitMap = uint8(index + MAX_INPUT_NUM);
        ife.exitMap = ife.exitMap.setBit(indexInExitMap);
    }

    function setOutputWithdrawData(
        InFlightExit storage ife,
        WithdrawData memory withdrawData,
        uint16 outputIndex
    )
        internal
    {
        ife.outputs[outputIndex] = withdrawData;
    }

    function isInFirstPhase(InFlightExit memory ife, uint256 minExitPeriod)
        internal
        view
        returns (bool)
    {
        uint256 periodTime = minExitPeriod / 2;
        return ((block.timestamp - ife.exitStartTimestamp) / periodTime) < 1;
    }

    function isInputPiggybacked(InFlightExit memory ife, uint16 index)
        internal
        pure
        returns (bool)
    {
        return ife.exitMap.bitSet(uint8(index));
    }

    function isOutputPiggybacked(InFlightExit memory ife, uint16 index)
        internal
        pure
        returns (bool)
    {
        uint8 indexInExitMap = uint8(index + MAX_INPUT_NUM);
        return ife.exitMap.bitSet(indexInExitMap);
    }

    function isFinalized(InFlightExit memory ife)
        internal
        pure
        returns (bool)
    {
        return Bits.bitSet(ife.exitMap, 255);
    }

    function isFirstPiggybackOfTheToken(InFlightExit memory ife, address token)
        internal
        pure
        returns (bool)
    {
        for (uint i = 0 ; i < MAX_INPUT_NUM ; i++) {
            if (isInputPiggybacked(ife, uint16(i)) && ife.inputs[i].token == token) {
                return false;
            }
        }

        for (uint i = 0 ; i < MAX_OUTPUT_NUM ; i++) {
            if (isOutputPiggybacked(ife, uint16(i)) && ife.outputs[i].token == token) {
                return false;
            }
        }

        return true;
    }
}
