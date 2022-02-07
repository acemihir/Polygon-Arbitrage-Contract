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
    address public immutable minter;
    ISwapRouter public uniswapV3Router;
    IUniswapV2Router02 public quickswapRouter;

    // Can buy at the following:
    // 0 = UniswapV3
    // 1 = Quickswap
    struct SwapData {
        uint8 index;
        address token;
        uint24 fee;
    }
    struct FlashData {
        SwapData buy;
        SwapData sell;
    }

    constructor(
        address _flashAddrProvider,
        address _uniswapV3Router,
        address _quickswapRouter
    ) FlashLoanReceiverBase(ILendingPoolAddressesProvider(_flashAddrProvider)) {
        minter = msg.sender;
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        quickswapRouter = IUniswapV2Router02(_quickswapRouter);
    }

    modifier minterOnly {
        require(msg.sender == minter, "CN: Minter only");
        _;
    }

    function execute(FlashData memory _data, uint256 _amount) external {
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

    function cashOut(address _receiver, address _token) external minterOnly {
        IERC20(_token).transfer(_receiver, IERC20(_token).balanceOf(address(this)));
    }

    function setUniswapV3Router(address _router) external minterOnly {
        uniswapV3Router = ISwapRouter(_router);
    }

    function setQuickswapRouter(address _router) external minterOnly {
        quickswapRouter = IUniswapV2Router02(_router);
    }

    // ============ Callback ============
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(LENDING_POOL), "CN: Malicious FL callback");

        FlashData memory decoded = abi.decode(params, (FlashData));
        uint256 sellAmount;
        // ============ Buy ============
        if (decoded.buy.index == 0) {
            // Buy at uniswapv3
            sellAmount = swapOnUniswapV3(uniswapV3Router, decoded.buy.token, decoded.sell.token, decoded.buy.fee, amounts[0]);
        } else if (decoded.buy.index == 1) {
            // Buy at quickswap
            sellAmount = swapOnUniswapV2(quickswapRouter, decoded.buy.token, decoded.sell.token, amounts[0]);
        }

        // ============ Sell ============
        if (decoded.sell.index == 0) {
            // Sell at uniswapv3, all sell tokens
            swapOnUniswapV3(uniswapV3Router, decoded.sell.token, decoded.buy.token, decoded.sell.fee, sellAmount);
        } else if (decoded.sell.index == 1) {
            // Sell at quickswap, all sell tokens
            swapOnUniswapV2(quickswapRouter, decoded.sell.token, decoded.buy.token, sellAmount);
        }

        // ============ Payback ============
        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        require(IERC20(assets[0]).approve(address(LENDING_POOL), amounts[0] + premiums[0]), "FL: Approve failed");

        return true;
    }

    // ============ Swaps ============
    function swapOnUniswapV3(ISwapRouter _router, address _tokenIn, address _tokenOut, uint24 _poolFee, uint256 _amountIn) private returns (uint256) {
        TransferHelper.safeApprove(_tokenIn, address(_router), _amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        
        return _router.exactInputSingle(params);
    }

    function swapOnUniswapV2(IUniswapV2Router02 _router, address _tokenIn, address _tokenOut, uint256 _amountIn) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        require(IERC20(_tokenIn).approve(address(_router), _amountIn), "V2: Approve failed");
        return _router.swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp)[0];
    }
    
    // ============ Testing ============
    // Make sure to send some of the _in token to the contract first.
    // function testV3(address _in, address _out) external {
    //     uint256 balance = IERC20(_in).balanceOf(address(this));
    //     TransferHelper.safeApprove(_in, address(uniswapV3Router), balance);

    //     ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
    //         tokenIn: _in,
    //         tokenOut: _out,
    //         fee: 3000,
    //         recipient: msg.sender,
    //         deadline: block.timestamp,
    //         amountIn: balance,
    //         amountOutMinimum: 0,
    //         sqrtPriceLimitX96: 0
    //     });
        
    //     uniswapV3Router.exactInputSingle(params);
    // }

    // Make sure to send some of the _in token to the contract first.
    // function testV2(address _in, address _out) external {
    //     address[] memory path = new address[](2);
    //     path[0] = _in;
    //     path[1] = _out;

    //     uint256 balance = IERC20(_in).balanceOf(address(this));
    //     TransferHelper.safeApprove(_in, address(quickswapRouter), balance);

    //     quickswapRouter.swapExactTokensForTokens(balance, 0, path, msg.sender, block.timestamp);
    // }
}
