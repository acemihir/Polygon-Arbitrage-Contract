// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.11;

import {IERC20} from "../interfaces/IERC20.sol";

import {IFlashLoanReceiver} from "../interfaces/IFlashLoanReceiver.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
    ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    ILendingPool public immutable LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }
}
