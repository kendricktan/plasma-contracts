pragma solidity ^0.5.0;


//temp name, will come up with better one
library Universal {

    struct WithdrawData {
        address payable exitTarget;
        address token;
        uint256 amount;
    }
}
