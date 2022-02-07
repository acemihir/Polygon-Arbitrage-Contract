import { expect } from 'chai';
import { ethers } from 'hardhat';

const MANA_ABI = [{"inputs":[{"internalType":"address","name":"_proxyTo","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_new","type":"address"},{"indexed":false,"internalType":"address","name":"_old","type":"address"}],"name":"ProxyOwnerUpdate","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_new","type":"address"},{"indexed":true,"internalType":"address","name":"_old","type":"address"}],"name":"ProxyUpdated","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proxyOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proxyType","outputs":[{"internalType":"uint256","name":"proxyTypeId","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferProxyOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newProxyTo","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"updateAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"_newProxyTo","type":"address"}],"name":"updateImplementation","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}];

describe("Swap Testing", async function () {
    let sender: any; 

    let testCntr: any;
    let manaCntr: any;

    beforeEach(async function () {
        const [deployer] = await ethers.getSigners();
        sender = deployer.address;

        const cntr = await ethers.getContractFactory("SwapTest");
        testCntr = await cntr.deploy();

        manaCntr = new ethers.Contract("0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4", MANA_ABI, deployer);
    });

    it("Should execute v3 swap", async function () {
        await testCntr.testV3(
            "0xE592427A0AEce92De3Edee1F18E0157C05861564",
            "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
            "0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4",
            50
        );

        // Check if MANA (0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4) has ~50 (> 0)
        expect(await manaCntr.functions.balanceOf(sender)).to.be.above(0);
    });

    it("Should execute v2 swap", async function () {
        await testCntr.testV2(
            "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff",
            "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
            "0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4",
            50
        );

        // Check if MANA (0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4) has ~100 (> 50)
        expect(await manaCntr.functions.balanceOf(sender)).to.be.above(50);
    });
});