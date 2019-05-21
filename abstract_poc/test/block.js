const MerkleTree = require("./merkle.js").MerkleTree

const MerkleTreeHeight = 16;

class Block {

  constructor(transactions) {
    this.txs = [];
    transactions.forEach(tx => this.addTransaction(tx));
  }

  addTransaction(tx) {
    const encodedTx = tx.rlpEncoded();
    this.txs.push(encodedTx);
    this.transactionTree = new MerkleTree(MerkleTreeHeight, this.txs);
  }

  getInclusionProof(tx) {
    const encodedTx = tx.rlpEncoded();
    return this.transactionTree.getInclusionProof(encodedTx);
  }

  getRoot() {
    return this.transactionTree.root;
  }
}

module.exports.Block = Block
