import { ethers } from 'hardhat';

async function main() {
    const [deployer] = await ethers.getSigners();

    const cntr = await ethers.getContractFactory("Arbitrage");
    const arbitrage = await cntr.deploy("0xd05e3E715d945B59290df0ae8eF85c1BdB684744");

    console.log(`Deployer: ${deployer.address}\nArbitrage: ${arbitrage.address}`);
}

main().catch((ex) => {
    console.error(ex);
    process.exitCode = 1;
});
