const rlp = require('rlp');

const NullData = '\00'.repeat(32);
const MaxUtxos = 4;

class TransactionInput {
  constructor(blknum, txindex, oindex) {
    this.blknum = blknum;
    this.txindex = txindex;
    this.oindex = oindex;
  }

  formatForRlpEncoding() {
    return [this.blknum, this.txindex, this.oindex]
  }
}

class TransactionOutput {
  constructor(outputType, amount, owner, token) {
    this.outputType = outputType;
    this.amount = amount;
    this.owner = owner;
    this.token = token;
  }

  formatForRlpEncoding() {
    return [this.outputType, [this.amount, this.owner, this.token]]
  }
}

class Witness {
  constructor(witness) {
    this.witness = witness;
  }

  formatForRlpEncoding() {
    return this.witness;
  }
}

class Transaction {
  constructor(transactionType, inputs, outputs, metaData = NullData) {
    this.transactionType = transactionType;
    this.inputs = inputs;
    this.outputs = outputs;
    this.metaData = metaData;
  }

  rlpEncoded() {
    const tx = [this.transactionType];

    tx.push(Transaction.formatForRlpEncoding(this.inputs));
    tx.push(Transaction.formatForRlpEncoding(this.outputs));
    tx.push(this.metaData);

    return rlp.encode(tx);
  }

  static formatForRlpEncoding(items) {
    return items.map(item => item.formatForRlpEncoding());
  }

  sign(signature) {
  }
}

class SimplePaymentTransaction extends Transaction {
  constructor(inputs, outputs, metaData = NullData) {
    super(1, inputs, outputs, metaData);
  }

  sign(spender) {
    const tx = [this.transactionType];

    tx.push(Transaction.formatForRlpEncoding(this.inputs));
    tx.push(Transaction.formatForRlpEncoding(this.outputs));
    tx.push(this.metaData);

    const encoded = rlp.encode(tx);
    return web3.utils.sha3(encoded);
  }
}

class FundingTransaction extends Transaction {
  constructor(inputs, outputs, metaData = NullData) {
    super(2, inputs, outputs, metaData);
  }
}

class BatchSettlementTransaction extends Transaction {
  constructor(inputs, outputs, metaData = NullData) {
    super(3, inputs, outputs, metaData);
  }
}

const BlknumOffset = 1000000000;
const OindexOffset = 10000;

class UtxoPosition {
  constructor(blknum, oindex, txindex) {
    this.blknum = blknum;
    this.oindex = oindex;
    this.txindex = txindex;
    this.utxoPos = BlknumOffset * blknum + OindexOffset * oindex + txindex;
  }

  encoded() {
    return this.utxoPos;
  }
}

module.exports.SimplePaymentTransaction = SimplePaymentTransaction
module.exports.FundingTransaction = FundingTransaction
module.exports.BatchSettlementTransaction = BatchSettlementTransaction
module.exports.TransactionInput = TransactionInput
module.exports.TransactionOutput = TransactionOutput
module.exports.UtxoPosition = UtxoPosition
module.exports.Witness = Witness
