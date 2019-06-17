const rlp = require('rlp');

const RLPMock = artifacts.require("RLPMock");

contract("RLP", () => {

    before(async () => {
        this.test = await RLPMock.new();
    });

    it("should decode bytes", async () => {
        const expected = Buffer.alloc(10, 1);
        const actual = Buffer.from(
            web3.utils.hexToBytes(await this.test.decodeBytes(expected, expected)) //FIXME: What's withthis double
        );
        expect(actual.compare(expected)).to.equal(0);
    });

    it("should decode bytes32", async () => {
        const expected = Buffer.alloc(32, 1);

        const encoded = rlp.encode(expected);
        const actual = Buffer.from(
            web3.utils.hexToBytes(await this.test.decodeBytes32(encoded, encoded))
        );
        expect(actual.compare(expected)).to.equal(0);
    });

    it("should decode bool", async () => {
        // false
        let bool = rlp.encode(new Buffer([0x00]));
        expect(await this.test.decodeBool(bool, bool)).is.false;

        // true
        bool = rlp.encode(new Buffer([0x01]));
        expect(await this.test.decodeBool(bool, bool)).is.true;
    });

    it("should decode uint", async () => {
        await testNumberDecoded(this.test.decodeUint, 0);
        await testNumberDecoded(this.test.decodeUint, 100);
    });

    it("should decode int", async () => {
        await testNumberDecoded(this.test.decodeInt, 0);
        await testNumberDecoded(this.test.decodeInt, 100);
    });

    async function testNumberDecoded(callback, expected) {
      const encoded = rlp.encode(expected);
      const actual = (await callback(encoded, encoded)).toNumber();
      expect(actual).is.equal(expected);
    }

    it("should decode array", async () => {
        const array = [[Buffer.alloc(32, 1)]]
        const encoded = rlp.encode(array);
        const arrayLength = (await this.test.decodeArray(encoded, encoded)).toNumber();
        expect(arrayLength).is.equal(array.length);
    });

    it("should decode deposit", async() => {
        const output = new TransactionOutput(DepositValue, alice, constants.ZERO_ADDRESS);
        const deposit = (new Transaction(1, [invalidInput], [output])).rlpEncoded();
        expect(await this.test.decodeDeposit(deposit, deposit)).to.be.equal(1);
    });
})
