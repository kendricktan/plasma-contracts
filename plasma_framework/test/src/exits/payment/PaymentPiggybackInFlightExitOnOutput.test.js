const PaymentInFlightExitRouter = artifacts.require('PaymentInFlightExitRouterMock');
const PaymentStartInFlightExit = artifacts.require('PaymentStartInFlightExit');
const PaymentSpendingConditionRegistry = artifacts.require('PaymentSpendingConditionRegistry');
const PaymentSpendingConditionFalse = artifacts.require('PaymentSpendingConditionFalse');
const PaymentSpendingConditionTrue = artifacts.require('PaymentSpendingConditionTrue');
const SpyPlasmaFramework = artifacts.require('SpyPlasmaFrameworkForExitGame');
const ExitId = artifacts.require('ExitIdWrapper');
const IsDeposit = artifacts.require('IsDepositWrapper');
const ExitableTimestamp = artifacts.require('ExitableTimestampWrapper');

const {
    BN, constants, expectEvent, expectRevert, time,
} = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const { MerkleTree } = require('../../../helpers/merkle.js');
const { buildUtxoPos, UtxoPos } = require('../../../helpers/positions.js');
const {
    addressToOutputGuard, computeNormalOutputId, spentOnGas,
} = require('../../../helpers/utils.js');
const { PaymentTransactionOutput, PaymentTransaction } = require('../../../helpers/transaction.js');

contract('PaymentInFlightExitRouter', ([_, alice, bob, carol]) => {
    describe('piggybackInFlightExitOnOutput', () => {
        it('should fail when index exceed max size of tx output', async () => {});
        it('should fail when no exit to piggyback on', async () => {});
        it('should fail when first phase of exit has passed', async () => {});
        it('should fail when the same output has been piggybacked', async () => {});

        describe('Given the output-to-exit is of output type 0', () => {
            it('should fail when not called by the exit target of the output', async () => {});
            it('should set the correct withdraw data on the output of exit data', async () => {});
        });

        describe('Given the output-to-exit is of non 0 output type', () => {
            it('should fail when output type + output gaurd data mismatch output.outputguard', async () => {});
            it('should fail when there is no outputguard parser for the output type', async () => {});
            it('should fail when not called by the exit target of the output', async () => {});
            it('should set the correct withdraw data on the output of exit data', async () => {});
        });

        describe('When piggyback successfully', () => {
            it('should enqueue when it is first piggyback of the exit on the token', () => {});
            it('should not enqueue when it is not first piggyback of the exit on the token', () => {});
            it('should set the exit as piggybacked on the index', () => {});
            it('should emit InFlightExitOutputPiggybacked event', () => {});
        });
    });
});
