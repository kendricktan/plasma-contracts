pragma solidity ^0.5.0;

import "./PriorityQueue.sol";

/**
 * @title PriorityQueueFactory
 * @dev Used solely to deploy new instances of a particular PriorityQueue implementation. Allows cheaper deployments
 */
library PriorityQueueFactory {
    function deploy(address _forOwner) public returns (address) {
        return address(new PriorityQueue(_forOwner));
    }
}
