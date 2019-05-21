const rlp = require('rlp');

const RLPTest = artifacts.require("RLPTest");

contract("RLP", accounts => {

    it("should decode a list", async () => {
          const test = await RLPTest.deployed();
          const arg = await rlp.encode(["a"]);
          await test.decodeList(arg);
          assert(true);
    });

    it("should decode bytes", async () => {
          const test = await RLPTest.deployed();
          const arg = await rlp.encode(["signature", ""]);
          await test.decodeBytes(arg);
          assert(true);
    });
})
