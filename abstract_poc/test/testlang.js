const TransactionInput = require("./transaction.js").TransactionInput
const TransactionOutput = require("./transaction.js").TransactionOutput
const SimplePaymentTransaction = require("./transaction.js").SimplePaymentTransaction

const StandardExitSpec = {
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
}

function startExit(args) {
     return web3.eth.abi.encodeFunctionCall(StandardExitSpec, args);
}

const DepositSpec = {
    name: 'deposit',
    type: 'function',
    inputs: [{
        type: 'bytes',
        name: '_depositTx'
    }]
}

const EthAddress = '\00'.repeat(20);
const TransactionTypes = {
  Deposit: 1,
  Transfer: 2
}

const DepositOutputType = 1;

const DepositInput = new TransactionInput(0, 0, 0);

function deposit(amount, owner, tokenAddress = EthAddress) {
  const txOutput = new TransactionOutput(DepositOutputType, amount, owner, tokenAddress);
  //TODO: use proper sig
  const deposit = new SimplePaymentTransaction([DepositInput], [txOutput], "signature");
  return deposit.rlpEncoded();
}

const StartExitSpec = {
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
}

function startStandardExit(utxoPos, transaction, block) {
  const inclusionProof = block.getInclusionProof(transaction);
  const encodedTx = transaction.rlpEncoded();
  const encodedUtxoPos = utxoPos.encoded();

  return web3.eth.abi.encodeFunctionCall(StartExitSpec, [encodedUtxoPos, encodedTx, web3.utils.hexToBytes(inclusionProof)]);
}

module.exports.startExit = startExit;
module.exports.deposit = deposit;
module.exports.startStandardExit = startStandardExit;
module.exports.EthAddress = EthAddress;
