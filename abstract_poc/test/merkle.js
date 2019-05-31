const NullHash = web3.utils.sha3('\00'.repeat(32));


class MerkleNode {
  constructor(data, left=null, right=null) {
    this.data = data;
    this.left = left;
    this.right = right;
  }
}

class MerkleTree {

  constructor(height, leaves) {
    if (height < 1) {
      throw "height must be a positive integer";
    }

    this.height = height;
    this.leaves = leaves;
    this.leafCount = 2 ** height;

    this.leaves = leaves.map(web3.utils.sha3);

    const fill = Array.from({length: this.leafCount - this.leaves.length}, (ignore1, ignore2) => NullHash);
    this.leaves = this.leaves.concat(fill);
    this.tree = [MerkleTree.create_nodes(this.leaves)];
    this.create_tree(this.tree[0]);
  }

  static create_nodes(leaves) {
     return leaves.map(leaf => new MerkleNode(leaf));
  }

  create_tree(level) {
    if (level.length == 1) {
      this.root = level[0].data;
      return;
    }

    const level_size = level.length;
    let next_level = [];

    let i = 0;
    while (i < level_size) {
      const combined = web3.utils.sha3(level[i].data + level[i + 1].data);
      const next_node = new MerkleNode(combined, level[i], level[i + 1]);
      next_level.push(next_node);
      i += 2;
    }

    this.tree.push(next_level);
    this.create_tree(next_level);
  }

  getInclusionProof(leaf) {
    const hashedLeaf = web3.utils.sha3(leaf);

    let index = this.leaves.indexOf(hashedLeaf);
    if (index == -1) {
      throw "Argument is not a leaf in the tree"
    }

    let proof = '0x';
    for (let i = 0; i < this.height; i++) {
      let sibling_index;
      if (index % 2 == 0) {
        sibling_index = index + 1;
      } else {
        sibling_index = index - 1;
      }
      index = Math.floor(index / 2);

      proof += this.tree[i][sibling_index].data.slice(2);
    }

    return proof;
  }
}

module.exports.MerkleTree = MerkleTree;