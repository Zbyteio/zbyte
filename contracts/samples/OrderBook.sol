// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/ZbyteContext.sol";

/**
 * @title OrderBook
 * @dev A decentralized order book contract for trading ERC20 tokens.
 */
contract OrderBook is ZbyteContext {
    IERC20 public base; ///< The base ERC20 token for trading.
    IERC20 public quote; ///< The quote ERC20 token for trading.

    /**
     * @dev Struct representing an order in the order book.
     */
    struct Order {
        uint256 id; ///< Unique identifier for the order.
        address trader; ///< Address of the trader placing the order.
        bool isBuyOrder; ///< Flag indicating if it's a buy order.
        uint256 price; ///< Price per token of the order.
        uint256 quantity; ///< Quantity of tokens in the order.
        bool isFilled; ///< Flag indicating if the order is filled.
        address baseToken; ///< ERC20 token address for the base asset.
        address quoteToken; ///< ERC20 token address for the quote asset.
    }

    Order[] public bidOrders; ///< Array to store bid (buy) orders.
    Order[] public askOrders; ///< Array to store ask (sell) orders.

    event OrderCanceled(
        uint256 indexed orderId,
        address indexed trader,
        bool isBuyOrder
    ); ///< Event emitted when an order is canceled.

    event TradeExecuted(
        uint256 indexed buyOrderId,
        uint256 indexed sellOrderId,
        address indexed buyer,
        address seller,
        uint256 price,
        uint256 quantity
    ); ///< Event emitted when a trade is executed.

    /**
     * @dev Constructor to set the trusted forwarder.
     * @param forwarder_ The address of the trusted forwarder.
     */
    constructor(address forwarder_) {
        _setTrustedForwarder(forwarder_);
    }

    /**
     * @dev Place a buy order.
     * @param price The price per token of the order.
     * @param quantity The quantity of tokens in the order.
     * @param baseToken The ERC20 token address for the base asset.
     * @param quoteToken The ERC20 token address for the quote asset.
     */
    function placeBuyOrder(
        uint256 price,
        uint256 quantity,
        address baseToken,
        address quoteToken
    ) external {
        uint256 orderValue = price * quantity;
        IERC20 quoteTokenContract = IERC20(quoteToken);
        require(
            quoteTokenContract.allowance(_msgSender(), address(this)) >=
                orderValue,
            "Insufficient allowance"
        );

        Order memory newOrder = Order({
            id: bidOrders.length,
            trader: _msgSender(),
            isBuyOrder: true,
            price: price,
            quantity: quantity,
            isFilled: false,
            baseToken: baseToken,
            quoteToken: quoteToken
        });

        insertBidOrder(newOrder);
        matchBuyOrder(newOrder.id);
    }

    /**
     * @dev Place a sell order.
     * @param price The price per token of the order.
     * @param quantity The quantity of tokens in the order.
     * @param baseToken The ERC20 token address for the base asset.
     * @param quoteToken The ERC20 token address for the quote asset.
     */
    function placeSellOrder(
        uint256 price,
        uint256 quantity,
        address baseToken,
        address quoteToken
    ) external {

        IERC20 baseTokenContract = IERC20(baseToken);

        require(
            baseTokenContract.allowance(_msgSender(), address(this)) >= quantity,
            "Insufficient allowance"
        );


        Order memory newOrder = Order({
            id: askOrders.length,
            trader: _msgSender(),
            isBuyOrder: false,
            price: price,
            quantity: quantity,
            isFilled: false,
            baseToken: baseToken,
            quoteToken: quoteToken
        });

        insertAskOrder(newOrder);

        matchSellOrder(newOrder.id);
    }

    /**
     * @dev Cancel an existing order.
     * @param orderId The ID of the order to cancel.
     * @param isBuyOrder Flag indicating if the order to cancel is a buy order.
     */
    function cancelOrder(uint256 orderId, bool isBuyOrder) external {
        Order storage order = isBuyOrder
            ? bidOrders[getBidOrderIndex(orderId)]
            : askOrders[getAskOrderIndex(orderId)];

        require(
            order.trader == _msgSender(),
            "Only the trader can cancel the order"
        );

        order.isFilled = true;
        emit OrderCanceled(orderId, _msgSender(), isBuyOrder);
    }

    /**
     * @dev Internal function to insert a new buy order into the bidOrders array
     * while maintaining sorted order (highest to lowest price).
     */
    function insertBidOrder(Order memory newOrder) internal {
        uint256 i = bidOrders.length;

        bidOrders.push(newOrder);

        while (i > 0 && bidOrders[i - 1].price < newOrder.price) {
            bidOrders[i] = bidOrders[i - 1];

            i--;
        }

        bidOrders[i] = newOrder;
    }

    /**
     * @dev Internal function to insert a new sell order into the askOrders array
     * while maintaining sorted order (lowest to highest price).
     */
    function insertAskOrder(Order memory newOrder) internal {
        uint256 i = askOrders.length;

        askOrders.push(newOrder);

        while (i > 0 && askOrders[i - 1].price > newOrder.price) {
            askOrders[i] = askOrders[i - 1];

            i--;
        }

        askOrders[i] = newOrder;
    }

    /**
     * @dev Internal function to match a buy order with compatible ask orders.
     */
    function matchBuyOrder(uint256 buyOrderId) internal {
        Order storage buyOrder = bidOrders[buyOrderId];

        for (uint256 i = 0; i < askOrders.length && !buyOrder.isFilled; i++) {
            Order storage sellOrder = askOrders[i];

            if (sellOrder.price <= buyOrder.price && !sellOrder.isFilled && sellOrder.baseToken == buyOrder.baseToken && sellOrder.quoteToken == buyOrder.quoteToken) {
                uint256 tradeQuantity = min(
                    buyOrder.quantity,
                    sellOrder.quantity
                );


                IERC20 baseTokenContract = IERC20(buyOrder.baseToken);

                IERC20 quoteTokenContract = IERC20(buyOrder.quoteToken);

                uint256 tradeValue = tradeQuantity * buyOrder.price;


                baseTokenContract.transferFrom(
                    sellOrder.trader,
                    buyOrder.trader,
                    tradeQuantity
                );


                quoteTokenContract.transferFrom(
                    buyOrder.trader,
                    sellOrder.trader,
                    tradeValue
                );


                buyOrder.quantity -= tradeQuantity;

                sellOrder.quantity -= tradeQuantity;

                buyOrder.isFilled = buyOrder.quantity == 0;

                sellOrder.isFilled = sellOrder.quantity == 0;

                emit TradeExecuted(
                    buyOrder.id,
                    i,
                    buyOrder.trader,
                    sellOrder.trader,
                    sellOrder.price,
                    tradeQuantity
                );
            }
        }
    }

    /**
     * @dev Internal function to match a sell order with compatible bid orders.
     */
    function matchSellOrder(uint256 sellOrderId) internal {
        Order storage sellOrder = askOrders[sellOrderId];

        for (uint256 i = 0; i < bidOrders.length && !sellOrder.isFilled; i++) {
            Order storage buyOrder = bidOrders[i];

            if (buyOrder.price >= sellOrder.price && !buyOrder.isFilled  && sellOrder.baseToken == buyOrder.baseToken && sellOrder.quoteToken == buyOrder.quoteToken) {
                uint256 tradeQuantity = min(
                    buyOrder.quantity,
                    sellOrder.quantity
                );


                IERC20 baseTokenContract = IERC20(sellOrder.baseToken);

                IERC20 quoteTokenContract = IERC20(sellOrder.quoteToken);

                uint256 tradeValue = tradeQuantity * sellOrder.price;


                baseTokenContract.transferFrom(
                    sellOrder.trader,
                    buyOrder.trader,
                    tradeQuantity
                );


                quoteTokenContract.transferFrom(
                    buyOrder.trader,
                    sellOrder.trader,
                    tradeValue
                );


                buyOrder.quantity -= tradeQuantity;

                sellOrder.quantity -= tradeQuantity;

                buyOrder.isFilled = buyOrder.quantity == 0;

                sellOrder.isFilled = sellOrder.quantity == 0;

                emit TradeExecuted(
                    buyOrder.id,
                    i,
                    buyOrder.trader,
                    sellOrder.trader,
                    sellOrder.price,
                    tradeQuantity
                );
            }
        }
    }

    /**
     * @dev Get the index of a buy order in the bidOrders array.
     */
    function getBidOrderIndex(uint256 orderId) public view returns (uint256) {
        require(orderId < bidOrders.length, "Order ID out of range");
        return orderId;
    }

    function getAskOrderLength() public view returns (uint256) {
        return askOrders.length;
    }

    function getBidOrderLength() public view returns (uint256) {
        return bidOrders.length;
    }

    /**
     * @dev Get the index of a sell order in the askOrders array.
     */
    function getAskOrderIndex(uint256 orderId) public view returns (uint256) {
        require(orderId < askOrders.length, "Order ID out of range");
        return orderId;
    }

    /**
     * @dev Helper function to find the minimum of two values.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
