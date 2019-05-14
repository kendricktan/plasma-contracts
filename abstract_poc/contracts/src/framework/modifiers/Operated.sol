pragma solidity ^0.5.0;

import "../PlasmaStorage.sol";

contract Operated is PlasmaStorage {
    modifier onlyOperator() {
        require(msg.sender == operator, "Not being called Operator");
        _;
    }

    function _initOperator() internal {
         require(operator == address(0), "Operator is already set, should not call _initOperator again.");
         operator = msg.sender;
    }
} 