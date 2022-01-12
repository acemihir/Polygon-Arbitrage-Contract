import { ethers } from 'hardhat';

async function main() {
    const [deployer] = await ethers.getSigners();

    const cntr = await ethers.getContractFactory("Arbitrage");
    const arbitrage = await cntr.deploy(
        "0xd05e3E715d945B59290df0ae8eF85c1BdB684744", // address _flashAddrProvider
        "0xE592427A0AEce92De3Edee1F18E0157C05861564", // address _uniswapV3Router
        "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff" // address _quickswapRouter
    );

    console.log(`Deployer: ${deployer.address}\nArbitrage: ${arbitrage.address}`);
}

main().catch((ex) => {
    console.error(ex);
    process.exitCode = 1;
});
