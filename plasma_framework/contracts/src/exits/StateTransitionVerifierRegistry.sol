pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./IStateTransitionVerifier.sol";

contract StateTransitionVerifierRegistry is Ownable {
    mapping(uint256 => IStateTransitionVerifier) private verifiers;

    function transitionVerifier(uint256 txType) public view returns (IStateTransitionVerifier) {
        return verifiers[txType];
    }

    /**
     * @notice Registers a verifier.
     * @param txType transaction type of transactions that are handled by provided verifier.
     * @param verifierAddress Address of the verifier.
     */
    function registerTransitionVerifier(uint256 txType, address verifierAddress)
        public
        onlyOwner
    {
        require(verifierAddress != address(0), "Should not register an empty address");
        require(address(verifiers[txType]) == address(0), "Verifier for the transaction type has already been registered");

        verifiers[txType] = IStateTransitionVerifier(verifierAddress);
    }
}