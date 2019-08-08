pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import './Universal.sol';

interface IStateTransitionVerifier {

    /**
    * @notice Verifies state transition logic.
    */
    function isCorrectStateTransition(
        bytes calldata inFlightTx,
        bytes[] calldata inputTxs,
        uint256[] calldata inputTxsTypes,
        uint256[] calldata inputUtxosPos
    )
        external
        view
        returns (Universal.WithdrawData[] memory);
}
