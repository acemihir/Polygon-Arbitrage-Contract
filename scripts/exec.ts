import { ethers } from 'hardhat';
import { abi } from '../artifacts/contracts/Arbitrage.sol/Arbitrage.json';

const ARBITRAGE_ADDRESS = "";

async function main() {
    const [deployer] = await ethers.getSigners();

    const cntr = new ethers.Contract(ARBITRAGE_ADDRESS, abi, deployer);
    await cntr.functions.execute({
        buy: {
            router: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
            tokenIn: "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
            poolFee: 3000,
            isV3: true
        },
        sell: {
            router: "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff",
            tokenIn: "0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4",
            poolFee: 3000,
            isV3: false
        }
    }, ethers.utils.parseUnits('1000', 18), { gasLimit: "30000000" });
}

main().catch((ex) => {
    console.error(ex);
    process.exitCode = 1;
});