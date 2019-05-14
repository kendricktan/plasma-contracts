pragma solidity ^0.5.0;

import "./PlasmaStorage.sol";
import "./modifiers/Operated.sol";
import "./models/BlockModel.sol";

contract PlasmaBlockController is PlasmaStorage, Operated {
    event BlockSubmitted(
        uint256 blockNumber
    );

    function submitBlock(bytes32 _blockRoot) public onlyOperator {
        uint256 submittedBlockNumber = nextChildBlock;

        blocks[submittedBlockNumber] = BlockModel.Block({
            root: _blockRoot,
            timestamp: block.timestamp
        });

        // Update the next child and deposit blocks.
        nextChildBlock += CHILD_BLOCK_INTERVAL;
        nextDepositBlock = 1;

        emit BlockSubmitted(submittedBlockNumber);
    }

    /**
     * @dev Calculates the next deposit block.
     * @return Next deposit block number.
     */
    function getDepositBlockNumber() public view returns (uint256) {
        return nextChildBlock - CHILD_BLOCK_INTERVAL + nextDepositBlock;
    }
}