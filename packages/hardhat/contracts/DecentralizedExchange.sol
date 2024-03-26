// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Importing OpenZeppelin contracts for ERC20 and SafeMath libraries
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decentralized Exchange
 * @dev This contract implements a simple decentralized exchange where users can trade ERC20 tokens with a fee system for the contract owner.
 */
contract DecentralizedExchange {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    // Structure to define an order
    struct Order {
        address trader;
        address tokenAddress;
        uint256 amount;
    }

    // Mapping to store orders with their unique IDs
    mapping(bytes32 => Order) public orderBook;

    // Address of the contract owner
    address public owner;
    // Fee percentage to be collected by the contract owner
    uint256 public feePercentage = 1; // 1% fee

    // Event to log trades
    event TradeExecuted(address indexed buyer, address indexed seller, uint256 amount, uint256 feeAmount);

    /**
     * @dev Constructor to set the owner of the contract.
     */
    constructor() {
        owner = msg.sender;
    }

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

        // Validate if there is enough balance for the trade
        uint256 buyAmount = buyOrder.amount;
        uint256 sellAmount = sellOrder.amount;
        uint256 feeAmount = (buyAmount * feePercentage) / 100;

        if (buyAmount <= sellAmount) {
            // Buy order amount is less than or equal to sell order amount
            // Transfer tokens and fees for the partial trade
            buyToken.safeTransfer(sellOrder.trader, buyAmount - feeAmount);
            sellToken.safeTransfer(buyOrder.trader, buyAmount);
            buyToken.safeTransfer(owner, feeAmount);

            // Update the sell order with the remaining amount
            sellOrder.amount -= buyAmount;
            orderBook[sellOrderId] = sellOrder;

            // Log the trade
            emit TradeExecuted(buyOrder.trader, sellOrder.trader, buyAmount, feeAmount);

            // Delete the buy order as it's fully executed
            delete orderBook[buyOrderId];
        } else {
            // Buy order amount is greater than sell order amount
            // Transfer tokens and fees for the full trade
            buyToken.safeTransfer(sellOrder.trader, sellAmount - feeAmount);
            sellToken.safeTransfer(buyOrder.trader, sellAmount);
            buyToken.safeTransfer(owner, feeAmount);

            // Update the buy order with the remaining amount
            buyOrder.amount -= sellAmount;
            orderBook[buyOrderId] = buyOrder;

            // Log the trade
            emit TradeExecuted(buyOrder.trader, sellOrder.trader, sellAmount, feeAmount);

            // Delete the sell order as it's fully executed
            delete orderBook[sellOrderId];
        }
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

    /**
     * @dev Function to update the fee percentage by the contract owner.
     * @param newFeePercentage The new fee percentage to be set.
     */
    function updateFeePercentage(uint256 newFeePercentage) external {
        require(msg.sender == owner, "Only the owner can update the fee percentage");
        feePercentage = newFeePercentage;
    }
}