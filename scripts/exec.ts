import { ethers } from 'hardhat';
import { abi } from '../artifacts/contracts/Arbitrage.sol/Arbitrage.json';

const ARBITRAGE_ADDRESS = "";

async function main() {
    const [deployer] = await ethers.getSigners();

    const cntr = new ethers.Contract(ARBITRAGE_ADDRESS, abi, deployer);
    await cntr.functions.execute({
        buy: {
            index: 0,
            token: '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270',
            fee: 3000
        },
        sell: {
            index: 1,
            token: '0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4',
            fee: 3000
        }
    }, ethers.utils.parseUnits('50'));
}

main().catch((ex) => {
    console.error(ex);
    process.exitCode = 1;
});
