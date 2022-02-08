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
    constructor() {}

    function testV3(address _router, address _in, address _out, uint256 _amount) external returns (uint256) {
        // Check for funds
        require(IERC20(_in).balanceOf(address(this)) >= _amount, "CN: Not enough funds.");
        // Approve the swap
        TransferHelper.safeApprove(_in, address(_router), _amount);

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

        uint256 output = ISwapRouter(_router).exactInputSingle(params);
        return output;
    }

    function testV2(address _router, address _in, address _out, uint256 _amount) external returns (uint256) {
        // Check for funds
        require(IERC20(_in).balanceOf(address(this)) >= _amount, "CN: Not enough funds.");
        // Approve the swap
        TransferHelper.safeApprove(_in, address(_router), _amount);

        address[] memory path = new address[](2);
        path[0] = _in;
        path[1] = _out;

        require(IERC20(_in).approve(_router, _amount), "V2: Approve failed");
        uint[] memory output = IUniswapV2Router02(_router).swapExactTokensForTokens(_amount, 0, path, msg.sender, block.timestamp);
        return output[0];
    }
}
