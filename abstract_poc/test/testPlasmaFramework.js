const {advanceTimeAndBlock} = require('./testllb/advanceTime.js');

const PriorityQueue = artifacts.require("PriorityQueue");
const PlasmaFramework = artifacts.require("PlasmaFramework");
const PaymentOutputToPaymentTxPredicate = artifacts.require("PaymentOutputToPaymentTxPredicate");
const SimplePaymentExitGame = artifacts.require("SimplePaymentExitGame");
const SimplePaymentExitProcessor = artifacts.require("SimplePaymentExitProcessor");
const FundingExitGame = artifacts.require("FundingExitGame");
const FundingExitProcessor = artifacts.require("FundingExitProcessor");
const EthVault = artifacts.require("EthVault");


const Testlang = require("./testlang.js")
const Block = require("./block.js").Block
const SimplePaymentTransaction = require("./transaction.js").SimplePaymentTransaction
const TransactionInput = require("./transaction.js").TransactionInput
const TransactionOutput = require("./transaction.js").TransactionOutput
const UtxoPosition = require("./transaction.js").UtxoPosition
const Witness = require("./transaction.js").Witness
const EthAddress = Testlang.EthAddress

contract("PlasmaFramework - MVP flow", accounts => {
    const alice = accounts[1];
    const DepositValue = 10000000;

    let plasma;
    let predicate;
    let exitGame;
    let exitProcessor;
    let block;

    before("setup contracts", async () => {
        plasma = await PlasmaFramework.deployed();
        ethVault = await EthVault.deployed();
        predicate = await PaymentOutputToPaymentTxPredicate.deployed();
        exitGame = await SimplePaymentExitGame.deployed();
        exitProcessor = await SimplePaymentExitProcessor.deployed();

        await plasma.registerOutputPredicate(1, 1, predicate.address, 1);
        await plasma.upgradeOutputPredicateTo(1, 1, 1);

        await plasma.registerExitProcessor(1, exitProcessor.address, 1);
        await plasma.upgradeExitProcessorTo(1, 1);

        await plasma.registerExitGame(1, exitGame.address, 1);
        await plasma.upgradeExitGameTo(1, 1);

        await plasma.registerVault(1, ethVault.address);
    });

    it("should register predicate and exit contracts", async () => {
        assert(await plasma.getOutputPredicate(1, 1) === predicate.address, 'predicate failed register');
        assert(await plasma.getExitProcessor(1) === exitProcessor.address, 'exitProcessor failed register');
        assert(await plasma.getExitGame(1) === exitGame.address, 'exitGame failed register');
    });

    it("should store a deposit", async () => {
        const deposit = Testlang.deposit(DepositValue, alice);
        await ethVault.deposit(deposit, {from: alice, value: web3.utils.toWei(DepositValue.toString(), 'wei')});
        const nextDepositBlock = parseInt(await plasma.nextDepositBlock(), 10);
        assert(nextDepositBlock === 2, `nextDepositBlock should be 2 instead of: [${nextDepositBlock}]`);
    });

    it("should run simple payment exit game", async () => {
        const txInput = new TransactionInput(1, 0, 0);
        const txOutput = new TransactionOutput(2, DepositValue, alice, EthAddress)
        const transaction = new SimplePaymentTransaction([txInput], [txOutput], [new Witness("signature")])
        const block = new Block([transaction]);
        await plasma.submitBlock(block.getRoot());

        const nextChildBlock = parseInt(await plasma.nextChildBlock(), 10);
        assert(nextChildBlock === 2000, `nextChildBlock should be 2000 instead of: [${nextChildBlock}]`);

        const exitingUtxo = new UtxoPosition(1000, 0, 0);
        const exit = Testlang.startStandardExit(exitingUtxo, transaction, block);
        await plasma.runExitGame(1, exit);

        const exitEvents = await exitGame.getPastEvents("ExitStarted");
        const exitId = exitEvents[0]['returnValues'].exitId;
        const exitType = exitEvents[0]['returnValues'].exitType;

        assert(exitId === exitingUtxo.encoded().toString() && (exitType === '1'));
    });

    it("should finalize exit", async () => {
      const aliceBalanceBeforeFinalization = await web3.eth.getBalance(alice);
      const tx = await plasma.processExits();
      const aliceBalancePostFinalization = await web3.eth.getBalance(alice);
      assert.equal(parseInt(aliceBalanceBeforeFinalization) + DepositValue, parseInt(aliceBalancePostFinalization))
    });
})
