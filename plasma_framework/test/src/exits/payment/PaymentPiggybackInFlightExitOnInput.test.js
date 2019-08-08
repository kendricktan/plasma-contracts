const ExitIdWrapper = artifacts.require('ExitIdWrapper');
const OutputGuardParserRegistry = artifacts.require('OutputGuardParserRegistry');
const PaymentInFlightExitRouter = artifacts.require('PaymentInFlightExitRouterMock');
const PaymentStartInFlightExit = artifacts.require('PaymentStartInFlightExit');
const PaymentSpendingConditionRegistry = artifacts.require('PaymentSpendingConditionRegistry');
const PaymentPiggybackInFlightExitOnInput = artifacts.require('PaymentPiggybackInFlightExitOnInput');
const PaymentPiggybackInFlightExitOnOutput = artifacts.require('PaymentPiggybackInFlightExitOnOutput');
const SpyPlasmaFramework = artifacts.require('SpyPlasmaFrameworkForExitGame');

const {
    BN, constants, expectEvent, expectRevert, time,
} = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const { buildUtxoPos, utxoPosToTxPos } = require('../../../helpers/positions.js');
const {
    addressToOutputGuard,
} = require('../../../helpers/utils.js');
const { PaymentTransactionOutput, PaymentTransaction } = require('../../../helpers/transaction.js');

contract.only('PaymentInFlightExitRouter', ([_, alice, bob]) => {
    const PIGGYBACK_BOND = 31415926535; // wei
    const ETH = constants.ZERO_ADDRESS;
    const MIN_EXIT_PERIOD = 60 * 60 * 24 * 7; // 1 week
    const DUMMY_INITIAL_IMMUNE_VAULTS_NUM = 0;
    const INITIAL_IMMUNE_EXIT_GAME_NUM = 1;
    const INFLIGHT_EXIT_YOUNGEST_INPUT_POSITION = buildUtxoPos(1000, 0, 0);
    const BLOCK_NUMBER = 5000;

    before('deploy and link with controller lib', async () => {
        const startInFlightExit = await PaymentStartInFlightExit.new();
        const piggybackInFlightExitOnInput = await PaymentPiggybackInFlightExitOnInput.new();
        const piggybackInFlightExitOnOutput = await PaymentPiggybackInFlightExitOnOutput.new();

        await PaymentInFlightExitRouter.link('PaymentStartInFlightExit', startInFlightExit.address);
        await PaymentInFlightExitRouter.link('PaymentPiggybackInFlightExitOnInput', piggybackInFlightExitOnInput.address);
        await PaymentInFlightExitRouter.link('PaymentPiggybackInFlightExitOnOutput', piggybackInFlightExitOnOutput.address);
    });

    describe('piggybackInFlightExitOnInput', () => {
        before(async () => {
            this.exitIdHelper = await ExitIdWrapper.new();
        });

        beforeEach(async () => {
            this.framework = await SpyPlasmaFramework.new(
                MIN_EXIT_PERIOD, DUMMY_INITIAL_IMMUNE_VAULTS_NUM, INITIAL_IMMUNE_EXIT_GAME_NUM,
            );

            const outputGuardParserRegistry = await OutputGuardParserRegistry.new();
            const spendingConditionRegistry = await PaymentSpendingConditionRegistry.new();

            this.exitGame = await PaymentInFlightExitRouter.new(
                this.framework.address, outputGuardParserRegistry.address, spendingConditionRegistry.address,
            );
        });

        const buildPiggybackInputData = async () => {
            const outputAmount = 997;
            const outputOwner = bob;
            const output = new PaymentTransactionOutput(outputAmount, addressToOutputGuard(outputOwner), ETH);

            const inFlightTx = new PaymentTransaction(1, [buildUtxoPos(BLOCK_NUMBER, 0, 0)], [output]);
            const rlpInFlighTxBytes = web3.utils.bytesToHex(inFlightTx.rlpEncoded());

            const emptyWithdrawData = {
                exitTarget: constants.ZERO_ADDRESS,
                token: constants.ZERO_ADDRESS,
                amount: 0,
            };

            const inputOwner = alice;
            const inFlightExitData = {
                exitStartTimestamp: (await time.latest()).toNumber(),
                exitMap: 0,
                position: INFLIGHT_EXIT_YOUNGEST_INPUT_POSITION,
                bondOwner: alice,
                oldestCompetitorPosition: 0,
                inputs: [{
                    exitTarget: inputOwner,
                    token: ETH,
                    amount: 999,
                }, {
                    exitTarget: inputOwner,
                    token: ETH,
                    amount: 998,
                }, emptyWithdrawData, emptyWithdrawData],
                outputs: [{
                    exitTarget: outputOwner,
                    token: ETH,
                    amount: outputAmount,
                }, emptyWithdrawData, emptyWithdrawData, emptyWithdrawData],
            };

            const exitId = await this.exitIdHelper.getInFlightExitId(rlpInFlighTxBytes);

            const args = {
                inFlightTx: rlpInFlighTxBytes,
                inputIndex: 0,
            };

            return {
                args,
                exitId,
                inputOwner,
                inFlightExitData,
            };
        };

        it('should fail when not send with the bond value', async () => {
            const { args } = await buildPiggybackInputData();
            await expectRevert(
                this.exitGame.piggybackInFlightExitOnInput(args),
                'Input value mismatches with msg.value',
            );
        });

        it('should fail when input index exceed max size of tx input', async () => {
            const { args } = await buildPiggybackInputData();
            const inputIndexExceedSize = 5;
            args.inputIndex = inputIndexExceedSize;
            await expectRevert(
                this.exitGame.piggybackInFlightExitOnInput(
                    args, { value: PIGGYBACK_BOND },
                ),
                'Index exceed max size of tx input',
            );
        });

        it('should fail when no exit to piggyback on', async () => {
            const data = await buildPiggybackInputData();
            await this.exitGame.setInFlightExit(data.exitId, data.inFlightExitData);

            const nonExistingTx = '0x';
            data.args.inFlightTx = nonExistingTx;
            await expectRevert(
                this.exitGame.piggybackInFlightExitOnInput(
                    data.args, { from: data.inputOwner, value: PIGGYBACK_BOND },
                ),
                'No in-flight exit to piggyback on',
            );
        });

        it('should fail when first phase of exit has passed', async () => {
            const data = await buildPiggybackInputData();

            data.inFlightExitData.exitStartTimestamp = 1; // super old start time
            await this.exitGame.setInFlightExit(data.exitId, data.inFlightExitData);

            await expectRevert(
                this.exitGame.piggybackInFlightExitOnInput(
                    data.args, { from: data.inputOwner, value: PIGGYBACK_BOND },
                ),
                'Can only piggyback in first phase of exit period',
            );
        });

        it('should fail when the same input has been piggybacked', async () => {
            const data = await buildPiggybackInputData();
            await this.exitGame.setInFlightExit(data.exitId, data.inFlightExitData);
            await this.exitGame.piggybackInFlightExitOnInput(
                data.args, { from: data.inputOwner, value: PIGGYBACK_BOND },
            );

            // second attmept should fail
            await expectRevert(
                this.exitGame.piggybackInFlightExitOnInput(
                    data.args, { from: data.inputOwner, value: PIGGYBACK_BOND },
                ),
                'The indexed input has been piggybacked already',
            );
        });

        it('should fail when not called by the exit target of the output', async () => {
            const data = await buildPiggybackInputData();
            await this.exitGame.setInFlightExit(data.exitId, data.inFlightExitData);

            const nonInputOwner = bob;
            await expectRevert(
                this.exitGame.piggybackInFlightExitOnInput(
                    data.args, { from: nonInputOwner, value: PIGGYBACK_BOND },
                ),
                'Can be called by the exit target of input only',
            );
        });

        describe('When piggyback successfully', () => {
            beforeEach(async () => {
                this.testData = await buildPiggybackInputData();
                await this.exitGame.setInFlightExit(this.testData.exitId, this.testData.inFlightExitData);
                this.piggybackTx = await this.exitGame.piggybackInFlightExitOnInput(
                    this.testData.args, { from: this.testData.inputOwner, value: PIGGYBACK_BOND },
                );
            });

            it('should enqueue when it is first piggyback of the exit on the token', async () => {
                await expectEvent.inTransaction(
                    this.piggybackTx.receipt.transactionHash,
                    SpyPlasmaFramework,
                    'EnqueueTriggered',
                    {
                        token: ETH,
                        // FIXME: test the correct value of exitable at
                        // exitableAt: this.inFlightExitData,
                        txPos: new BN(utxoPosToTxPos(INFLIGHT_EXIT_YOUNGEST_INPUT_POSITION)),
                        exitProcessor: this.exitGame.address,
                        exitId: this.testData.exitId,
                    },
                );
            });

            it('should not enqueue when it is not first piggyback of the exit on the same token', async () => {
                this.testData.args.inputIndex = 1;
                await this.exitGame.setInFlightExit(this.testData.exitId, this.testData.inFlightExitData);
                expect((await this.framework.enqueuedCount()).toNumber()).to.equal(1);
            });

            it('should set the exit as piggybacked on the index', async () => {});

            it('should emit InFlightExitInputPiggybacked event', async () => {
                await expectEvent.inTransaction(
                    this.piggybackTx.receipt.transactionHash,
                    PaymentPiggybackInFlightExitOnInput,
                    'InFlightExitInputPiggybacked',
                    {
                        owner: this.testData.inputOwner,
                        txHash: web3.utils.sha3(this.testData.args.inFlightTx),
                        inputIndex: new BN(this.testData.args.inputIndex),
                    },
                );
            });
        });
    });
});
