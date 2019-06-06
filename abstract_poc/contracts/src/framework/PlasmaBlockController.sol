pragma solidity ^0.5.0;

import "./PlasmaStorage.sol";
import "./modifiers/Operated.sol";
import "./modifiers/OnlyFromVault.sol";
import "./models/BlockModel.sol";
import "./utils/Merkle.sol";
import "./utils/PlasmaCore.sol";

contract PlasmaBlockController is PlasmaStorage, Operated, OnlyFromVault {

    using PlasmaCore for uint256;
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

    /**
     * @dev Checks that a given transaction was included in a block and created a specified output.
     * @param _tx RLP encoded transaction to verify.
     * @param _transactionPos Transaction position for the encoded transaction.
     * @param _txInclusionProof Proof that the transaction was in a block.
     * @return True if the transaction was in a block and created the output. False otherwise.
     */
    function transactionIncluded(bytes memory _tx, uint256 _transactionPos, bytes memory _txInclusionProof)
        public
        view
        returns (bool)
    {
        // Decode the transaction ID.
        uint256 blknum = _transactionPos.getBlknum();
        uint256 txindex = _transactionPos.getTxIndex();


        // Check that the transaction was correctly included.
        bytes32 blockRoot = blocks[blknum].root;
        bytes32 leafHash = keccak256(_tx);
        return Merkle.checkMembership(leafHash, txindex, blockRoot, _txInclusionProof);
    }

}
