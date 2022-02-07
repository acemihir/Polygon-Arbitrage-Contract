// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import {IERC20} from "./interfaces/IERC20.sol";

// UniswapV3
import "./interfaces/ISwapRouter.sol";
import "./libraries/TransferHelper.sol";
// UniswapV2
import "./interfaces/IUniswapV2Router02.sol";

contract SwapTest {
    ISwapRouter public uniswapV3Router;
    IUniswapV2Router02 public quickswapRouter;

    constructor() {}

    function testV3(address _router, address _in, address _out, uint256 _amount) external {
        TransferHelper.safeApprove(_in, address(uniswapV3Router), _amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _in,
            tokenOut: _out,
            fee: 3000,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        
        ISwapRouter(_router).exactInputSingle(params);
    }

    function swapOnUniswapV2(address _router, address _tokenIn, address _tokenOut, uint256 _amountIn) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        require(IERC20(_tokenIn).approve(_router, _amountIn), "V2: Approve failed");
        return IUniswapV2Router02(_router).swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp)[0];
    }
}
