pragma solidity ^0.5.0;

library PaymentInFlightExitRouterArgs {
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
    * @notice Wraps arguments for piggybackInFlightExitOnInput.
    * @param inFlightTx RLP encoded in-flight transaction.
    * @param inputIndex index of the input to piggypack on.
    */
    struct PiggybackInFlightExitOnInputArgs {
        bytes inFlightTx;
        uint16 inputIndex;
    }

    /**
    * @notice Wraps arguments for piggybackInFlightExitOnOutput.
    * @param inFlightTx RLP encoded in-flight transaction.
    * @param outputIndex Index of the output to piggyback on.
    * @param outputType The output type of the piggyback output.
    * @param outputGuardData The original data (pre-image) for the outputguard.
    */
    struct PiggybackInFlightExitOnOutputArgs {
        bytes inFlightTx;
        uint16 outputIndex;
        uint256 outputType;
        bytes outputGuardData;
    }
}
