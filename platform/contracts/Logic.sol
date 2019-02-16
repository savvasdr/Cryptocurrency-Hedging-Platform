/*
     ███████╗████████╗██╗  ██╗███████╗██████╗ ███████╗██╗   ██╗███╗   ███╗
     ██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝██║   ██║████╗ ████║
     █████╗     ██║   ███████║█████╗  ██████╔╝█████╗  ██║   ██║██╔████╔██║
     ██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██║╚██╔╝██║
     ███████╗   ██║   ██║  ██║███████╗██║  ██║███████╗╚██████╔╝██║ ╚═╝ ██║
     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝
                   ____                 _ _           _ _   
                  / __ \               | (_)         (_) |  
                 | |  | |_ __ __ _  ___| |_ _______   _| |_ 
                 | |  | | '__/ _` |/ __| | |_  / _ \ | | __|
                 | |__| | | | (_| | (__| | |/ /  __/_| | |_ 
                 \____/|_|  \__,_|\___|_|_/___\___(_)_|\__|
                   
 _                                                      _                       _   
( )                   _                                ( )_                    ( )_ 
| |       _      __  (_)   ___       ___    _     ___  | ,_) _ __   _ _    ___ | ,_)
| |  _  /'_`\  /'_ `\| | /'___)    /'___) /'_`\ /' _ `\| |  ( '__)/'_` ) /'___)| |  
| |_( )( (_) )( (_) || |( (___    ( (___ ( (_) )| ( ) || |_ | |  ( (_| |( (___ | |_ 
(____/'`\___/'`\__  |(_)`\____)   `\____)`\___/'(_) (_)`\__)(_)  `\__,_)`\____)`\__)
              ( )_) |                                                               
               \___/'                                                               
*/
pragma solidity ^0.4.20;    // Tested on version 0.4.25

    /*
     * Import Oraclize to use their oracles..
    */
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";

    /*
     * Use this interface to take tha Data contract address from proxy contract.
    */
contract ProxyInterface {
    function getDataContractAddress() public view returns (address);
    function getAutoMatchContractAddress() public view returns (address);
}

    /*
     * Use this interface to take tha Data contract address from proxy contract.
    */
contract AutoMatchInterface {
    function autoMatching() public payable returns(bool);
    function allOrdersMatched() public view returns(bool);
}

    /*
     * Use this interface to use Data ccontract functions.
    */
contract DataInterface {
    function editOrdersAmount(address _user, uint128 _newAmount, bool _openOrder) external payable returns(bool);
    function addOpenOrder(address _user, bool _storeOfValue, uint128 _amount) external payable returns(uint);
    function editOrdersArray(address _user, bool _push, bool _openOrder, bool _storeOfValue, uint _number) external payable returns(bool);
    function removeSpecificOpenOrder(uint _orderId, bool _storeOfValue) external payable returns(bool);
    function returnMoney(address _user, uint128 _amount) external payable returns(bool);
    function addMatchedOrder(address _userA, address _userB, uint128 _amount, uint32 _etherPrice) external payable returns(uint);
    function disableMatchedOrder(uint _orderId) external payable returns(bool);
    function removeOldestOpenOrder(bool _storeOfValue) external payable returns(bool);
    function decraseStoreOfValueBySpecificAmount(uint _orderId, uint128 _amount) external payable returns(bool);
    function decraseIncreasePriceBySpecificAmount(uint _orderId, uint128 _amount) external payable returns(bool);
    function editOpenOrder(uint _index, bool _storeOfValue, uint128 _amount) external payable returns(bool);
    
    /*
     * Getters
    */
    function getUserStoreOfValueOpenOrders(address _user) external view returns(uint[]);
    function getUserPriceIncreaseOpenOrders(address _user) external view returns(uint[]);
    function getUserMatchedOrders(address _user) external view returns(uint[]);
    function returnUserInformation(address _user) external view returns(uint128, uint128, uint[], uint[], uint[]);
    function getMatchedOrder(uint _orderId) external view returns(address, address, uint128, uint32, bool);
    function getUserAmount(address _user, bool _openOrder) external view returns(uint128);
    function getUserOpenOrder(uint _orderId, bool _storeOfValue) external view returns(address, uint128);
    function getStoreOfValueOrders() external view returns(uint[]);
    function getIncreaseValueOrders() external view returns(uint[]);
    function getStoreOfValueOrderInformation(uint _orderId) external view returns(address, uint128);
    function getPriceIncreaseOrderInformation(uint _orderId) external view returns(address, uint128);
}


contract LogicContract is usingOraclize {

    /*
    ********************    CONTRACT INFORMATION    ******************** 
     * This contract holds the Logic of the platform. 
     *    
     * The methods can be called from users, checks their data
     * and call the corresponding methods from Data contract.
    */
    
    /*
     * Initialize with proxy contract address.
    */
    address private proxyAddress;
    constructor(address _proxyAddress) public {
        proxyAddress = _proxyAddress;
        
        // Get the current ETH/USD price for free.
        updatePrice();
    }
    
    /*
     * Set modifier so public functions can be called only from the
     * Logic contract and not from any other contract.
    */
    modifier recentPrice {
        require(haveRecentETHprice());
        _;
    }
    
    /*
     * Get Data contract address from the proxy contract.
    */
    function getDataContractAddress() private view returns (address) {
        return ProxyInterface(proxyAddress).getDataContractAddress();
    }
    
    /*
     * Get Data contract address from the proxy contract.
    */
    function getAutoMatchContractAddress() private view returns (address) {
        return ProxyInterface(proxyAddress).getAutoMatchContractAddress();
    }
    
    /*
     * @ETHUSD is the latest known ETH/USD price.
     * @latestBlock is the block number at which we have got the latest ETH/USD price.
     * @blockNumberLimit et the limit of how old price can be acceptable (in blocks).
    */
    uint32 private ETHUSD;
    uint256 private latestBlock;
    uint256 private blockNumberLimit = 50;
    
    /*
     * Accepts the money that user sends and creates a new open order.
     * 
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
    */
    function addNewOrder(bool _storeOfValue) public payable returns(bool) {

        // Check for amount overflow.
        require(msg.value < 2**128);
        
        // Minumum order is 0.001 ether
        require(msg.value >= 10**15);
        
        // Add the open order
        require(DataInterface(getDataContractAddress()).editOrdersAmount.value(msg.value)(msg.sender, DataInterface(getDataContractAddress()).getUserAmount(msg.sender, true) + uint128(msg.value), true));
        uint orderId = DataInterface(getDataContractAddress()).addOpenOrder(msg.sender, _storeOfValue, uint128(msg.value));
        require(DataInterface(getDataContractAddress()).editOrdersArray(msg.sender, true, true, _storeOfValue, orderId));
        
        // Do auto-matching.
        while(!AutoMatchInterface(getAutoMatchContractAddress()).allOrdersMatched()){
            AutoMatchInterface(getAutoMatchContractAddress()).autoMatching();
        }
        return true;
    }
    
    /*
     * A user can complete his specific order and distribute the money to both users.
     * 
     * @_orderId is the order ID that user want to complete.
    */
    function completedOrder(uint _orderId) public recentPrice payable returns(bool) {
        // Confirm that users owns this order
        address _userA;
        address _userB;
        uint128 _amount;
        uint32 _etherPrice;
        bool _active;
        
        // Get the information about this order.
        (_userA, _userB, _amount, _etherPrice, _active) = DataInterface(getDataContractAddress()).getMatchedOrder(_orderId);
        
        // Checks thath the user owns this matched order.
        require(msg.sender == _userA || msg.sender == _userB);
        
        // Make distrubition
        uint128 _distrubitionUserA;
        uint128 _distrubitionUserB;
        if (_etherPrice >= ETHUSD * 2) {
            require(DataInterface(getDataContractAddress()).returnMoney(_userA, _amount*2));
        } else {
            _distrubitionUserA = _etherPrice * _amount / ETHUSD;
            _distrubitionUserB = 2 * _amount - _distrubitionUserA;
            require(DataInterface(getDataContractAddress()).returnMoney(_userA, _distrubitionUserA));
            require(DataInterface(getDataContractAddress()).returnMoney(_userB, _distrubitionUserB));
        }
        
        // Delete it from matched orders
        require(DataInterface(getDataContractAddress()).disableMatchedOrder(_orderId));
        require(DataInterface(getDataContractAddress()).editOrdersAmount(_userA, DataInterface(getDataContractAddress()).getUserAmount(_userA, false)-_amount, false));
        require(DataInterface(getDataContractAddress()).editOrdersArray(_userA, false, false, true, _orderId));
        require(DataInterface(getDataContractAddress()).editOrdersAmount(_userB, DataInterface(getDataContractAddress()).getUserAmount(_userB, false)-_amount, false));
        require(DataInterface(getDataContractAddress()).editOrdersArray(_userB, false, false, true, _orderId));
        
        return true;
    }
    
    /*
     * User can cancel his open order and get back his money.
     * 
     * @_orderId is the order ID that user wants to cancel.
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
    */
    function cancelOpenOrder(uint _orderId, bool _storeOfValue) public payable returns(bool) {
        // Confirm that users owns this order
        address user;
        uint128 amount;
        (user, amount) = DataInterface(getDataContractAddress()).getUserOpenOrder(_orderId, _storeOfValue);
        require(msg.sender == user && amount > 0);
        
        // Check for underflow 
        require(DataInterface(getDataContractAddress()).getUserAmount(msg.sender, true) - amount < DataInterface(getDataContractAddress()).getUserAmount(msg.sender, true));
        
        // Delete the order
        require(DataInterface(getDataContractAddress()).editOrdersAmount(user, DataInterface(getDataContractAddress()).getUserAmount(user, true) - amount, true));
        require(DataInterface(getDataContractAddress()).editOrdersArray(user, false, true, _storeOfValue, _orderId));
        require(DataInterface(getDataContractAddress()).removeSpecificOpenOrder(_orderId, _storeOfValue));
        require(DataInterface(getDataContractAddress()).editOpenOrder(_orderId, _storeOfValue, 0));

        // Return money
        require(DataInterface(getDataContractAddress()).returnMoney(user, amount));

        return true;
    }
    
    /*
     * Gets the latest ETH/USD price. 
     * It gets price of ether in USD, as a string.
     * Code from: http://docs.oraclize.it/#ethereum
    */
    event LogConstructorInitiated(string nextStep);
    event LogPriceUpdated(string price);
    event LogNewOraclizeQuery(string description);
    function updatePrice() public payable returns(bool) {
        if (oraclize_getPrice("URL") > msg.value) {
            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some more ETH to cover for the query fee");
            return false;
        } else {
            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer...");
            oraclize_query("URL", "json(https://api.infura.io/v1/ticker/ethusd).bid");
            return true;
        }
    }
    
    /*
     * Oraclize calls this callback function to send the ETH/USD.
     * It's a string so we are responsible to convert and save it.
    */
    function __callback(bytes32 myid, string result) public {
        if (msg.sender != oraclize_cbAddress()) revert();
        
        // Price is returned as String. We turn it to uint32. We avoid the decimal part.
        ETHUSD = uint32(parseInt(result, 0));
        
        // Keep this block number.
        latestBlock = block.number;
        
        emit LogPriceUpdated(result);
    }
    
    /*
     * Get the query fee in Wei.
    */
    function estimateGas() public view returns (uint) {
        return oraclize_getPrice("URL");
    }

    /*
     * Checks that we have a recent ETH/USD price.
    */
    function haveRecentETHprice() public view returns (bool) {
        return (block.number - blockNumberLimit < latestBlock);
    }

    /*
    ********************    VARIOUS GETTERS    ******************** 
     * Getters used for the front-end application.
    */
    
    /*
     * Get "Store of value" open orders for the specific user.
    */
    function getUserStoreOfValueOpenOrders() external view returns(uint[]) {
        return DataInterface(getDataContractAddress()).getUserStoreOfValueOpenOrders(msg.sender);
    }
    
    /*
     * Get "Price iincrease bet" open orders for the specific user.
    */
    function getUserPriceIncreaseOpenOrders() external view returns(uint[]) {
        return DataInterface(getDataContractAddress()).getUserPriceIncreaseOpenOrders(msg.sender);
    }
    
    /*
     * Get the matched orders for the specific user.
    */
    function getUserMatchedOrders() external view returns(uint[]) {
        return DataInterface(getDataContractAddress()).getUserMatchedOrders(msg.sender);
    }
    
    /*
     * Get information for the specific user.
    */
    function returnUserInformation() external view returns(uint128, uint128, uint[], uint[], uint[]) {
        return DataInterface(getDataContractAddress()).returnUserInformation(msg.sender);
    }    
    
    /*
     * Get the latest saved ETH/USD price.
    */
    function getETHUSDprice() external view returns(uint32) {
        return ETHUSD;
    }
    
    /*
     * Get the latest block number (for the last price we have).
    */
    function getLatestBlock() external view returns(uint256) {
        return latestBlock;
    }
    
    /*
     * Get the block number limit.
    */
    function getBlockNumberLimit() external view returns(uint256) {
        return blockNumberLimit;
    }
}