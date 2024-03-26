// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Importing OpenZeppelin contracts for ERC20 and SafeMath libraries
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decentralized Exchange
 * @dev This contract implements a simple decentralized exchange where users can trade ERC20 tokens.
 */
contract DecentralizedExchange {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    struct Order {
        address trader;
        address tokenAddress;
        uint256 amount;
    }

    mapping(bytes32 => Order) public orderBook;

    /**
     * @dev Function to submit a buy limit order.
     * @param tokenAddress The address of the token to buy.
     * @param amount The amount of tokens to buy.
     */
    function submitBuyOrder(address tokenAddress, uint256 amount) external {
        ERC20 token = ERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        bytes32 orderId = keccak256(abi.encode(msg.sender, tokenAddress, amount));
        orderBook[orderId] = Order(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Function to submit a sell limit order.
     * @param tokenAddress The address of the token to sell.
     * @param amount The amount of tokens to sell.
     */
    function submitSellOrder(address tokenAddress, uint256 amount) external {
        ERC20 token = ERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        bytes32 orderId = keccak256(abi.encode(msg.sender, tokenAddress, amount));
        orderBook[orderId] = Order(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Function to execute a trade between two orders.
     * @param buyOrderId The ID of the buy order.
     * @param sellOrderId The ID of the sell order.
     */
    function executeTrade(bytes32 buyOrderId, bytes32 sellOrderId) external {
        Order memory buyOrder = orderBook[buyOrderId];
        Order memory sellOrder = orderBook[sellOrderId];
        require(buyOrder.trader != address(0), "Buy order does not exist");
        require(sellOrder.trader != address(0), "Sell order does not exist");

        ERC20 buyToken = ERC20(buyOrder.tokenAddress);
        ERC20 sellToken = ERC20(sellOrder.tokenAddress);
        require(buyToken.balanceOf(address(this)) >= buyOrder.amount, "Insufficient balance for buy order");
        require(sellToken.balanceOf(address(this)) >= sellOrder.amount, "Insufficient balance for sell order");

        buyToken.safeTransfer(sellOrder.trader, buyOrder.amount);
        sellToken.safeTransfer(buyOrder.trader, sellOrder.amount);

        delete orderBook[buyOrderId];
        delete orderBook[sellOrderId];
    }

    /**
     * @dev Function to cancel a buy or sell order.
     * @param orderId The ID of the order to cancel.
     */
    function cancelOrder(bytes32 orderId) external {
        Order memory order = orderBook[orderId];
        require(order.trader != address(0), "Order does not exist");

        ERC20 token = ERC20(order.tokenAddress);
        token.safeTransfer(order.trader, order.amount);

        delete orderBook[orderId];
    }
}