const PlasmaFramework = artifacts.require("PlasmaFramework");
const PaymentOutputToPaymentTxPredicate = artifacts.require("PaymentOutputToPaymentTxPredicate");
const SimplePaymentExitGame = artifacts.require("SimplePaymentExitGame");
const SimplePaymentExitProcessor = artifacts.require("SimplePaymentExitProcessor");

contract("PlasmaFramework", accounts => {
    it("should be able to deploy", async () => {
        const instance = await PlasmaFramework.deployed();
        assert(instance);
    });

    it("should be able to deposit", async () => {
        const plasma = await PlasmaFramework.deployed();
        await plasma.deposit(web3.utils.fromUtf8("dummy bytes"));
        const nextDepositBlock = parseInt(await plasma.nextDepositBlock(), 10);
        assert(nextDepositBlock === 2, `nextDepositBlock should be 2 instead of: [${nextDepositBlock}]`);
    });

    it("should be able to submit block", async () => {
        const plasma = await PlasmaFramework.deployed();
        await plasma.submitBlock(web3.utils.fromUtf8("dummy bytes"));
        const nextChildBlock = parseInt(await plasma.nextChildBlock(), 10);
        assert(nextChildBlock === 2000, `nextChildBlock should be 2000 instead of: [${nextChildBlock}]`);
    });

    it("should be able to deploy and register predicate and exit contracts", async () => {
        const plasma = await PlasmaFramework.deployed();
        const predicate = await PaymentOutputToPaymentTxPredicate.deployed();
        const exitGame = await SimplePaymentExitGame.deployed();
        const exitProcessor = await SimplePaymentExitProcessor.deployed();

        await plasma.registerOutputPredicate(1, 1, predicate.address, 1);
        await plasma.upgradeOutputPredicateTo(1, 1, 1);

        await plasma.registerExitProcessor(1, exitProcessor.address, 1);
        await plasma.upgradeExitProcessorTo(1, 1);

        await plasma.registerExitGame(1, exitGame.address, 1);
        await plasma.upgradeExitGameTo(1, 1);

        assert(await plasma.getOutputPredicate(1, 1) === predicate.address, 'predicate failed register');
        assert(await plasma.getExitProcessor(1) === exitProcessor.address, 'exitProcessor failed register');
        assert(await plasma.getExitGame(1) === exitGame.address, 'exitGame failed register');
    });

    it("should be able to start exit and challenge with simple payment tx", async () => {
        const plasma = await PlasmaFramework.deployed();
        const predicate = await PaymentOutputToPaymentTxPredicate.deployed();
        const exitGame = await SimplePaymentExitGame.deployed();
        const exitProcessor = await SimplePaymentExitProcessor.deployed();

        await plasma.registerOutputPredicate(1, 1, predicate.address, 1);
        await plasma.upgradeOutputPredicateTo(1, 1, 1);

        await plasma.registerExitProcessor(1, exitProcessor.address, 1);
        await plasma.upgradeExitProcessorTo(1, 1);

        await plasma.registerExitGame(1, exitGame.address, 1);
        await plasma.upgradeExitGameTo(1, 1);

        const startStandardExit = web3.eth.abi.encodeFunctionCall({
            name: 'startStandardExit',
            type: 'function',
            inputs: [{
                type: 'uint192',
                name: '_utxoPos'
            },{
                type: 'bytes',
                name: '_outputTx'
            },{
                type: 'bytes',
                name: '_outputTxInclusionProof'
            }]
        }, [123, web3.utils.fromUtf8("dummy tx"), web3.utils.fromUtf8("dummy proof")])
        await plasma.runExitGame(1, startStandardExit);
        
        //TODO: add assert on storage change
        EXIT_ID = '0x000000000000000000000000000000000000000000000000000000000000007b';
        const exitDataOrigin = await plasma.getBytesStorage(1, EXIT_ID);
        const decodedExitDataOrigin = web3.eth.abi.decodeParameter({
            SimplePaymentExitDataModel: {
                exitId: 'uint256',
                exitType: 'uint8',
                exitable: 'bool',
                outputHash: 'bytes32',
                token: 'address',
                exitTarget: 'address',
                amount: 'uint256'
            }
        }, exitDataOrigin);

        assert(decodedExitDataOrigin.exitable, "exit started and exitable");

        const dummyOutput = web3.eth.abi.encodeParameter({
            TxOutput: {
                outputType: 'uint256',
                outputData: {
                    amount: 'uint256',
                    owner: 'address',
                    token: 'address',
                },
            }
        }, {
            outputType: 1, 
            outputData: {
                amount: 10, 
                owner: '0x0000000000000000000000000000000000000000', 
                token: '0x0000000000000000000000000000000000000000'
            }
        });

        const challengeCall = web3.eth.abi.encodeFunctionCall({
            name: 'challengeStandardExitOutputUsed',
            type: 'function',
            inputs: [{
                type: 'uint192',
                name: '_standardExitId'
            },{
                type: 'bytes',
                name: '_output'
            },{
                type: 'bytes',
                name: '_challengeTx'
            }, {
                type: 'uint256',
                name: '_challengeTxType'
            }, {
                type: 'uint8',
                name: '_inputIndex'
            }]
        }, [123, dummyOutput, web3.utils.fromUtf8("dummy tx"), 1, 0])
        await plasma.runExitGame(1, challengeCall);

        const exitDataChallenged = await plasma.getBytesStorage(1, EXIT_ID);
        const decodedExitDataChallenged = web3.eth.abi.decodeParameter({
            SimplePaymentExitDataModel: {
                exitId: 'uint256',
                exitType: 'uint8',
                exitable: 'bool',
                outputHash: 'bytes32',
                token: 'address',
                exitTarget: 'address',
                amount: 'uint256'
            }
        }, exitDataChallenged);
        assert(decodedExitDataChallenged.exitable === false, "successfully challenged");
    });


    it("should be able to exit from funding tx", async () => {
        const plasma = await PlasmaFramework.deployed();
        const exitGame = await SimplePaymentExitGame.deployed();
        const exitProcessor = await SimplePaymentExitProcessor.deployed();

        await plasma.registerOutputPredicate(1, 1, predicate.address, 1);
        await plasma.upgradeOutputPredicateTo(1, 1, 1);

        await plasma.registerExitProcessor(1, exitProcessor.address, 1);
        await plasma.upgradeExitProcessorTo(1, 1);

        await plasma.registerExitGame(1, exitGame.address, 1);
        await plasma.upgradeExitGameTo(1, 1);

        const startStandardExit = web3.eth.abi.encodeFunctionCall({
            name: 'startStandardExit',
            type: 'function',
            inputs: [{
                type: 'uint192',
                name: '_utxoPos'
            },{
                type: 'bytes',
                name: '_outputTx'
            },{
                type: 'bytes',
                name: '_outputTxInclusionProof'
            }]
        }, [123, web3.utils.fromUtf8("dummy tx"), web3.utils.fromUtf8("dummy proof")])
        await plasma.runExitGame(1, startStandardExit);
        
        //TODO: add assert on storage change
        EXIT_ID = '0x000000000000000000000000000000000000000000000000000000000000007b';
        const exitDataOrigin = await plasma.getBytesStorage(1, EXIT_ID);
        const decodedExitDataOrigin = web3.eth.abi.decodeParameter({
            SimplePaymentExitDataModel: {
                exitId: 'uint256',
                exitType: 'uint8',
                exitable: 'bool',
                outputHash: 'bytes32',
                token: 'address',
                exitTarget: 'address',
                amount: 'uint256'
            }
        }, exitDataOrigin);

        assert(decodedExitDataOrigin.exitable, "exit started and exitable");

        const dummyOutput = web3.eth.abi.encodeParameter({
            TxOutput: {
                outputType: 'uint256',
                outputData: {
                    amount: 'uint256',
                    owner: 'address',
                    token: 'address',
                },
            }
        }, {
            outputType: 1, 
            outputData: {
                amount: 10, 
                owner: '0x0000000000000000000000000000000000000000', 
                token: '0x0000000000000000000000000000000000000000'
            }
        });

        const challengeCall = web3.eth.abi.encodeFunctionCall({
            name: 'challengeStandardExitOutputUsed',
            type: 'function',
            inputs: [{
                type: 'uint192',
                name: '_standardExitId'
            },{
                type: 'bytes',
                name: '_output'
            },{
                type: 'bytes',
                name: '_challengeTx'
            }, {
                type: 'uint256',
                name: '_challengeTxType'
            }, {
                type: 'uint8',
                name: '_inputIndex'
            }]
        }, [123, dummyOutput, web3.utils.fromUtf8("dummy tx"), 1, 0])
        await plasma.runExitGame(1, challengeCall);

        const exitDataChallenged = await plasma.getBytesStorage(1, EXIT_ID);
        const decodedExitDataChallenged = web3.eth.abi.decodeParameter({
            SimplePaymentExitDataModel: {
                exitId: 'uint256',
                exitType: 'uint8',
                exitable: 'bool',
                outputHash: 'bytes32',
                token: 'address',
                exitTarget: 'address',
                amount: 'uint256'
            }
        }, exitDataChallenged);
        assert(decodedExitDataChallenged.exitable === false, "successfully challenged");
    });
})