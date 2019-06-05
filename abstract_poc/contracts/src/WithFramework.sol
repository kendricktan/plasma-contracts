pragma solidity ^0.5.0;

import "./framework/PlasmaFramework.sol";

interface WithFramework {
    // Function to make sure there is getter of plasma framework.
    function framework() external returns (PlasmaFramework);
}
