const PlasmaFramework = artifacts.require("PlasmaFramework");

contract("PlasmaFramework", accounts => {
    it("should be able to compile", async () => {
        const instance = await PlasmaFramework.deployed();
        assert(instance);
    });
})