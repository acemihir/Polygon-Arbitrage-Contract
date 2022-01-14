import { ethers } from 'hardhat';
import { abi } from '../artifacts/contracts/Arbitrage.sol/Arbitrage.json';

const ARBITRAGE_CONTRACT = '';
const LUNA_TOKEN = '';
const WETH_TOKEN = '';
const LUNA_FEE = 3000;

async function main() {
    const [deployer] = await ethers.getSigners();
    
    const cntr = new ethers.Contract(ARBITRAGE_CONTRACT, abi, deployer);

    const flashData = {
        buy: {
            index: 0,
            token: WETH_TOKEN, // buy token0, sell token1
            fee: LUNA_FEE
        },
        sell: {
            index: 1,
            token: LUNA_TOKEN, // sell token0, buy token1
            fee: 0
        }
    }
    await cntr.functions.execute(flashData);
}

main().catch((ex) => {
    console.error(ex);
    process.exitCode = 1;
});
