pragma solidity ^0.5.0;

import "./PlasmaStorage.sol";
import "./modifiers/Operated.sol";
import "./modifiers/OnlyFromVault.sol";
import "./models/BlockModel.sol";

contract PlasmaBlockController is PlasmaStorage, Operated, OnlyFromVault {
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

    function submitDepositBlock(bytes32 _blockRoot) public onlyFromVault {
        require(nextDepositBlock < CHILD_BLOCK_INTERVAL, "Exceed limit of deposits per child block interval");

        uint256 blknum = getDepositBlockNumber();
        blocks[blknum] = BlockModel.Block({
            root : _blockRoot,
            timestamp : block.timestamp
        });

        nextDepositBlock++;
    }

    /**
     * @dev Calculates the next deposit block.
     * @return Next deposit block number.
     */
    function getDepositBlockNumber() private view returns (uint256) {
        return nextChildBlock - CHILD_BLOCK_INTERVAL + nextDepositBlock;
    }
}