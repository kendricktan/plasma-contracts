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

    it("should be able to proxy to exit game contracts", async () => {
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

        const functionSignature = web3.eth.abi.encodeFunctionCall({
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
        await plasma.runExitGame(1, functionSignature);
        
        //TODO: add assert on storage change
    });
})