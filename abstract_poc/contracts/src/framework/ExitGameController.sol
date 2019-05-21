pragma solidity ^0.5.0;
//Should be safe to use. It is marked as experimental as it costs higher gas usage.
//see: https://github.com/ethereum/solidity/issues/5397
pragma experimental ABIEncoderV2;

import "./PlasmaStorage.sol";
import "./models/ExitModel.sol";
import "./interfaces/ExitProcessor.sol";
import "./registries/ExitGameRegistry.sol";
import "./priorityQueue/PriorityQueue.sol";
import "./modifiers/ExitGameWhitelisted.sol";

contract ExitGameController is PlasmaStorage, ExitGameRegistry, ExitGameWhitelisted {
    /**
     * @dev Proxy function that calls the app contract to run the specific interactive game function.
     * @param _txType tx type. each type has its own exit game contract.
     * @param _encodedFunctionData Encoded function data, including function abi and input variables.
     * eg. for a function "f(uint 256)", this value should be abi.encodeWithSignature("f(uint256)", var1)
     */
    function runExitGame(uint256 _txType, bytes memory _encodedFunctionData) public {
        (bool success, bytes memory data) = getExitGame(_txType).call(_encodedFunctionData);
        require(success, string(abi.encodePacked("runExitGame in Exit Game contract failed with data: [ ", string(data), " ]")));
    }

    function enqueue(uint192 _priority, ExitModel.Exit memory _exit) public onlyExitGame returns (uint256) {
        uint256 uniquePriority = (uint256(_priority) << 64 | exitQueueNonce);
        exitQueueNonce++;

        queue.insert(uniquePriority);
        exits[uniquePriority] = _exit;

        return uniquePriority;
    }

    function processExits() external {
        uint256 uniquePriority = queue.getMin();
        ExitModel.Exit memory exit = exits[uniquePriority];

        // FIX: <= used until we introduce proper exit finalization margin
        while (exit.exitableAt <= block.timestamp) {
            ExitProcessor processor = ExitProcessor(exit.exitProcessor);
            processor.processExit(exit.exitId);

            queue.delMin();

            if (queue.currentSize() == 0) {
              return;
            }

            uniquePriority = queue.getMin();
            exit = exits[uniquePriority];
        }
    }
}
