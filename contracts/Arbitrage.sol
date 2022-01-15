// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import {FlashLoanReceiverBase} from "./utils/FlashLoanReceiverBase.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "./interfaces/ILendingPoolAddressesProvider.sol";
import {IERC20} from "./interfaces/IERC20.sol";

// UniswapV3
import "./interfaces/ISwapRouter.sol";
import "./libraries/TransferHelper.sol";
// UniswapV2
import "./interfaces/IUniswapV2Router02.sol";

contract Arbitrage is FlashLoanReceiverBase {
    address public immutable owner;

    ISwapRouter public immutable uniswapV3Router;
    IUniswapV2Router02 public immutable quickswapRouter;

    struct SwapData {
        uint8 index;
        address token;
        uint24 fee;
    }

    // Can buy at the following:
    // 0 = UniswapV3
    // 1 = Quickswap
    struct FlashData {
        SwapData buy;
        SwapData sell;
    }

    constructor(
        address _flashAddrProvider,
        address _uniswapV3Router,
        address _quickswapRouter
    ) FlashLoanReceiverBase(ILendingPoolAddressesProvider(_flashAddrProvider)) {
        owner = msg.sender;
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        quickswapRouter = IUniswapV2Router02(_quickswapRouter);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }

    function execute(FlashData memory _data, uint256 _amount) external onlyOwner {
        address[] memory assets = new address[](1);
        assets[0] = address(_data.buy.token);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        LENDING_POOL.flashLoan(
            address(this), // receiver
            assets,
            amounts,
            modes,
            address(this), // on behalf of
            abi.encode(_data),
            0 // referralCode
        );
    }

    // ============ Callbacks ============
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(LENDING_POOL), "Not a lending pool.");

        FlashData memory decoded = abi.decode(params, (FlashData));
        // ============ Buy ============
        if (decoded.buy.index == 0) {
            // Buy at uniswapv3
            swapOnUniswapV3(uniswapV3Router, decoded.buy.token, decoded.sell.token, decoded.buy.fee);
        } else if (decoded.buy.index == 1) {
            // Buy at quickswap
            swapOnUniswapV2(quickswapRouter, decoded.buy.token, decoded.sell.token);
        }

        // ============ Sell ============
        if (decoded.sell.index == 0) {
            // Sell at uniswapv3
            swapOnUniswapV3(uniswapV3Router, decoded.sell.token, decoded.buy.token, decoded.sell.fee);
        } else if (decoded.sell.index == 1) {
            // Sell at quickswap
            swapOnUniswapV2(quickswapRouter, decoded.sell.token, decoded.buy.token);
        }

        // ============ Payback ============
        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        uint256 amountOwed = amounts[0] + premiums[0];
        IERC20(assets[0]).approve(address(LENDING_POOL), amountOwed);

        // Calculate profit
        uint256 balance = IERC20(assets[0]).balanceOf(address(this));
        require(amountOwed <= balance, "No profit was made"); // Check for arithmic underflow

        // Pay the profit to the owner
        IERC20(assets[0]).transfer(owner, balance - amountOwed);

        return true;
    }

    function swapOnUniswapV3(ISwapRouter _router, address _tokenIn, address _tokenOut, uint24 _poolFee) private returns (uint256) {
        uint256 balance = IERC20(_tokenIn).balanceOf(address(this));
        TransferHelper.safeApprove(_tokenIn, address(_router), balance);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: balance,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        
        return _router.exactInputSingle(params);
    }

    function swapOnUniswapV2(IUniswapV2Router02 _router, address _tokenIn, address _tokenOut) private {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256 balance = IERC20(_tokenIn).balanceOf(address(this));
        TransferHelper.safeApprove(_tokenIn, address(_router), balance);

        _router.swapExactTokensForTokens(balance, 0, path, address(this), block.timestamp);
    }
}
