/*
     ███████╗████████╗██╗  ██╗███████╗██████╗ ███████╗██╗   ██╗███╗   ███╗
     ██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝██║   ██║████╗ ████║
     █████╗     ██║   ███████║█████╗  ██████╔╝█████╗  ██║   ██║██╔████╔██║
     ██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██║╚██╔╝██║
     ███████╗   ██║   ██║  ██║███████╗██║  ██║███████╗╚██████╔╝██║ ╚═╝ ██║
     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝

                           _              __  __       _       _     
                /\        | |            |  \/  |     | |     | |    
               /  \  _   _| |_ ___ ______| \  / | __ _| |_ ___| |__  
              / /\ \| | | | __/ _ \______| |\/| |/ _` | __/ __| '_ \ 
             / ____ \ |_| | || (_) |     | |  | | (_| | || (__| | | |
            /_/    \_\__,_|\__\___/      |_|  |_|\__,_|\__\___|_| |_|
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
     * Use this interface to take the Logic & Data contract address from proxy contract.
    */
contract ProxyInterface {
    function getDataContractAddress() public view returns (address);
    function getLogicContractAddress() public view returns (address);
}

    /*
     * Use this interface to use Data ccontract functions.
    */
contract DataInterface {
    function editOrdersAmount(address _user, uint128 _newAmount, bool _openOrder) external payable returns(bool);
    function editOrdersArray(address _user, bool _push, bool _openOrder, bool _storeOfValue, uint _number) external payable returns(bool);
    function addMatchedOrder(address _userA, address _userB, uint128 _amount, uint32 _etherPrice) external payable returns(uint);
    function removeOldestOpenOrder(bool _storeOfValue) external payable returns(bool);
    function decraseStoreOfValueBySpecificAmount(uint _orderId, uint128 _amount) external payable returns(bool);
    function decraseIncreasePriceBySpecificAmount(uint _orderId, uint128 _amount) external payable returns(bool);
    function editOpenOrder(uint _index, bool _storeOfValue, uint128 _amount) external payable returns(bool);
    
    /*
     * Getters
    */
    function getUserAmount(address _user, bool _openOrder) external view returns(uint128);
    function getStoreOfValueOrders() external view returns(uint[]);
    function getIncreaseValueOrders() external view returns(uint[]);
    function getStoreOfValueOrderInformation(uint _orderId) external view returns(address, uint128);
    function getPriceIncreaseOrderInformation(uint _orderId) external view returns(address, uint128);
    function getUserOpenOrder(uint _orderId, bool _storeOfValue) external view returns(address, uint128);
}

    /*
     * Use this interface to use Logic ccontract functions.
    */
contract LogicInterface {
    function getETHUSDprice() external view returns(uint32);
    function haveRecentETHprice() public view returns (bool);
}

contract AutoMatch {

    /*
    ********************    CONTRACT INFORMATION    ******************** 
     * This contract implements the Auto-matching function of the platform. 
     *    
     * Can be called only from Logic contract.
    */
    
    /*
     * Initialize with proxy contract address.
    */
    address private proxyAddress;
    constructor(address _proxyAddress) public {
        proxyAddress = _proxyAddress;
    }
    
    /*
     * Get Logic contract address from the proxy contract.
    */
    function getLogicContractAddress() private view returns (address) {
        return ProxyInterface(proxyAddress).getLogicContractAddress();
    }
    
    /*
     * Get Data contract address from the proxy contract.
    */
    function getDataContractAddress() private view returns (address) {
        return ProxyInterface(proxyAddress).getDataContractAddress();
    }
   
    /*
     * Set modifier so public functions can be called only from the
     * Logic contract and not from any other contract.
    */
    modifier haveRecentPrice {
        require(LogicInterface(getLogicContractAddress()).haveRecentETHprice());
        _;
    }

    /**
     * This function is called after any new order is added.
     * Matches open orders (if it is possible)
     */
    function autoMatching() public haveRecentPrice payable returns(bool) {
        // Check if are available matches.
        if (DataInterface(getDataContractAddress()).getStoreOfValueOrders().length == 0 || DataInterface(getDataContractAddress()).getIncreaseValueOrders().length == 0) {
            return false;
        }
        
        bool storeOfValueIsSmaller;
        uint StoreOfValueID = DataInterface(getDataContractAddress()).getStoreOfValueOrders()[0];
        uint IncreasepriceID = DataInterface(getDataContractAddress()).getIncreaseValueOrders()[0];
        address StoreOfValueAddress;
        address IncreasePriceAddress;
        uint128 StoreOfValueAmount;
        uint128 IncreasePriceAmount;
        uint128 newOrderAmount;
        uint newOrderId;
        (StoreOfValueAddress, StoreOfValueAmount) = DataInterface(getDataContractAddress()).getStoreOfValueOrderInformation(StoreOfValueID);
        (IncreasePriceAddress, IncreasePriceAmount) = DataInterface(getDataContractAddress()).getPriceIncreaseOrderInformation(IncreasepriceID);
        
        // Handle the case we have orders with the same amount 
        if (StoreOfValueAmount == IncreasePriceAmount) {
            // Assign new order ammount
            newOrderAmount = StoreOfValueAmount;
            
            // Delete the order from the active open orders array for both users.
            require((DataInterface(getDataContractAddress())).removeOldestOpenOrder(true));
            require((DataInterface(getDataContractAddress())).removeOldestOpenOrder(false));
            
            // Data underflow check.
            require(DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, true) - newOrderAmount < DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, true));
            require(DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, true) - newOrderAmount < DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, true));
            
            // Decrease the new amount from open orders amount for both users.
            require(DataInterface(getDataContractAddress()).editOrdersAmount(StoreOfValueAddress, DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, true) - newOrderAmount, true));
            require(DataInterface(getDataContractAddress()).editOrdersAmount(IncreasePriceAddress, DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, true) - newOrderAmount, true));
            require(DataInterface(getDataContractAddress()).editOpenOrder(StoreOfValueID, true, 0));
            require(DataInterface(getDataContractAddress()).editOpenOrder(IncreasepriceID, false, 0));

            // Delete the order for both users.
            require(DataInterface(getDataContractAddress()).editOrdersArray(StoreOfValueAddress, false, true, true, StoreOfValueID));
            require(DataInterface(getDataContractAddress()).editOrdersArray(IncreasePriceAddress, false, true, false, IncreasepriceID));
            
            // Add the matched order
            newOrderId = DataInterface(getDataContractAddress()).addMatchedOrder(StoreOfValueAddress, IncreasePriceAddress, newOrderAmount, LogicInterface(getLogicContractAddress()).getETHUSDprice());
            require(DataInterface(getDataContractAddress()).editOrdersAmount(StoreOfValueAddress, DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, false) + newOrderAmount, false));
            require(DataInterface(getDataContractAddress()).editOrdersAmount(IncreasePriceAddress, DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, false) + newOrderAmount, false));
            require(DataInterface(getDataContractAddress()).editOrdersArray(StoreOfValueAddress, true, false, false, newOrderId));
            require(DataInterface(getDataContractAddress()).editOrdersArray(IncreasePriceAddress, true, false, false, newOrderId));
 
            return true;
        }
        
        // Find the order with the smaller amount.
        if (StoreOfValueAmount < IncreasePriceAmount) {
            storeOfValueIsSmaller = true;
            newOrderAmount = StoreOfValueAmount;
        } else {
            newOrderAmount = IncreasePriceAmount;
        }
        
        // Delete the order with the smallest amount from the active open orders array.
        require((DataInterface(getDataContractAddress())).removeOldestOpenOrder(storeOfValueIsSmaller));
        
        // Data underflow check.
        require(DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, true) - newOrderAmount < DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, true));
        require(DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, true) - newOrderAmount < DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, true));
        
        // Decrease the new amount from open orders amount for both users.
        require(DataInterface(getDataContractAddress()).editOrdersAmount(StoreOfValueAddress, DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, true) - newOrderAmount, true));
        require(DataInterface(getDataContractAddress()).editOrdersAmount(IncreasePriceAddress, DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, true) - newOrderAmount, true));
        if (storeOfValueIsSmaller) {
            require(DataInterface(getDataContractAddress()).editOpenOrder(StoreOfValueID, true, 0));
            require(DataInterface(getDataContractAddress()).decraseIncreasePriceBySpecificAmount(IncreasepriceID, newOrderAmount));
            
            //(, tempAmount) = DataInterface(getDataContractAddress()).getUserOpenOrder(IncreasepriceID, false);
            //require(DataInterface(getDataContractAddress()).editOpenOrder(IncreasepriceID, false, tempAmount - newOrderAmount));
        } else {
            require(DataInterface(getDataContractAddress()).editOpenOrder(IncreasepriceID, false, 0));
            require(DataInterface(getDataContractAddress()).decraseStoreOfValueBySpecificAmount(StoreOfValueID, newOrderAmount));
            //(, tempAmount) = DataInterface(getDataContractAddress()).getUserOpenOrder(StoreOfValueID, true);
            //require(DataInterface(getDataContractAddress()).editOpenOrder(StoreOfValueID, true, tempAmount - newOrderAmount));
        }

        // Delete from the user the order with the smallest amount.
        if (storeOfValueIsSmaller) {
            require(DataInterface(getDataContractAddress()).editOrdersArray(StoreOfValueAddress, false, true, true, StoreOfValueID));
        } else {
            require(DataInterface(getDataContractAddress()).editOrdersArray(IncreasePriceAddress, false, true, false, IncreasepriceID));
        }
        
        // Add the matched order
        newOrderId = DataInterface(getDataContractAddress()).addMatchedOrder(StoreOfValueAddress, IncreasePriceAddress, newOrderAmount, LogicInterface(getLogicContractAddress()).getETHUSDprice());
        require(DataInterface(getDataContractAddress()).editOrdersAmount(StoreOfValueAddress, DataInterface(getDataContractAddress()).getUserAmount(StoreOfValueAddress, false) + newOrderAmount, false));
        require(DataInterface(getDataContractAddress()).editOrdersAmount(IncreasePriceAddress, DataInterface(getDataContractAddress()).getUserAmount(IncreasePriceAddress, false) + newOrderAmount, false));
        require(DataInterface(getDataContractAddress()).editOrdersArray(StoreOfValueAddress, true, false, false, newOrderId));
        require(DataInterface(getDataContractAddress()).editOrdersArray(IncreasePriceAddress, true, false, false, newOrderId));
        
        return true;
    }
    
    /**
     * Getter returns if all possible orders are matched.
     */
    function allOrdersMatched() public view returns(bool) {
        return (DataInterface(getDataContractAddress()).getStoreOfValueOrders().length == 0 || DataInterface(getDataContractAddress()).getIncreaseValueOrders().length == 0);
    }
}