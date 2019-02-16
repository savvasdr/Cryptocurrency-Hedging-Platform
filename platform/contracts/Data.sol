/*
    ███████╗████████╗██╗  ██╗███████╗██████╗ ███████╗██╗   ██╗███╗   ███╗
    ██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝██║   ██║████╗ ████║
    █████╗     ██║   ███████║█████╗  ██████╔╝█████╗  ██║   ██║██╔████╔██║
    ██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██║╚██╔╝██║
    ███████╗   ██║   ██║  ██║███████╗██║  ██║███████╗╚██████╔╝██║ ╚═╝ ██║
    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝
 ___           _                                   _                       _   
(  _`\        ( )_                                ( )_                    ( )_ 
| | ) |   _ _ | ,_)   _ _       ___    _     ___  | ,_) _ __   _ _    ___ | ,_)
| | | ) /'_` )| |   /'_` )    /'___) /'_`\ /' _ `\| |  ( '__)/'_` ) /'___)| |  
| |_) |( (_| || |_ ( (_| |   ( (___ ( (_) )| ( ) || |_ | |  ( (_| |( (___ | |_ 
(____/'`\__,_)`\__)`\__,_)   `\____)`\___/'(_) (_)`\__)(_)  `\__,_)`\____)`\__)

*/
pragma solidity ^0.4.25;    // Tested on version 0.4.25

    /*
     * Use this interface to take the Logic contract address from proxy contract.
    */
contract ProxyInterface {
    function getLogicContractAddress() public view returns (address);
    function getAutoMatchContractAddress() public view returns (address);
}

contract DataContract {
    
    
    /*
    ********************    CONTRACT INFORMATION    ******************** 
     * This contract holds the Data of the platform. 
     *    
     * The methods can be called only from Logic contract,
     * so there are not many checks done here.
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
     * Get Auto Match contract address from the proxy contract.
    */
    function getAutoMatchContractAddress() private view returns (address) {
        return ProxyInterface(proxyAddress).getAutoMatchContractAddress();
    }
   
    /*
     * Set modifier so public functions can be called only from the
     * Logic contract and not from any other contract.
    */
    modifier onlyLogicContract {
        require(msg.sender == getLogicContractAddress() || msg.sender == getAutoMatchContractAddress());
        _;
    }
    
    /*
    ********************    USER INFORMATION    ******************** 
    * We need a struct that will keep information about the orders of each user.
    * By using a mapping we can easy find all the orders of a specific user.
    * 
    * @openOrdersAmount keep the total amount of open orders of this user.
    * @matchedOrdersAmount keep the total amount of matched orders of this user.
    * @storeOfValueOpenOrders keep the unique ID's of "Store of Value" open orders of this user.
    * @increasePriceOpenOrders keep the unique ID's of "Price increase bet" open orders of this user.
    * @matchedOrders keep the unique ID's of all matched orders of this user.
    */
    struct User {
        uint128 openOrdersAmount;
        uint128 matchedOrdersAmount;
        uint[] storeOfValueOpenOrders;
        uint[] increasePriceOpenOrders;
        uint[] matchedOrders;
    }
    mapping(address => User) private users;
    
    /*
     * This function edits the [openOrdersAmount] and [matchedOrdersAmount] of a specific user.
     * 
     * @_user is the address of the user.
     * @_newAmount is the new value of the amount for this user.
     * @_openOrder selects if we refer to an open order (True) or to a matched order (False)
    */
    function editOrdersAmount(address _user, uint128 _newAmount, bool _openOrder) external onlyLogicContract payable returns(bool) {
        // Edit openOrdersAmount
        if (_openOrder) {
            users[_user].openOrdersAmount = _newAmount;
            return true;
        } 
        // Edit matchedOrdersAmount
        else { 
            users[_user].matchedOrdersAmount = _newAmount;
            return true;
        }
    }
    
    /*
     * Adds or deletes element from [storeOfValueOpenOrders], [increasePriceOpenOrders] and [matchedOrders].
     * 
     * @_user is the address of the user.
     * @_push adds/push a new element (True) or deletes an existing element (False).
     * @_openOrder refers to an open order (True) or to a matched order (False).
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
     * @_number refers to the order number/ID.
    */
    function editOrdersArray(address _user, bool _push, bool _openOrder, bool _storeOfValue, uint _number) external onlyLogicContract payable returns(bool) {
        // Push new order to storeOfValueOpenOrders
        if (_push == true && _openOrder == true && _storeOfValue == true) {
            users[_user].storeOfValueOpenOrders.push(_number);
            return true;
        }
        // Push new order to increasePriceOpenOrders
        else if (_push == true && _openOrder == true && _storeOfValue == false) {
            users[_user].increasePriceOpenOrders.push(_number);
            return true;
        }
        // Push new order to matchedOrders
        else if (_push == true && _openOrder == false) {
            users[_user].matchedOrders.push(_number);
            return true;
        }
        // Delete element from storeOfValueOpenOrders (by number)
        else if (_push == false && _openOrder == true && _storeOfValue == true) {
            return deleteArrayElement(users[_user].storeOfValueOpenOrders, _number);
        }
        // Delete element from increasePriceOpenOrders (by number)
        else if (_push == false && _openOrder == true && _storeOfValue == false) {
            return deleteArrayElement(users[_user].increasePriceOpenOrders, _number);
        }
        // Delete element from matchedOrders (by number)
        else if (_push == false && _openOrder == false) {
            return deleteArrayElement(users[_user].matchedOrders, _number);
        }
        return false;
    }

    /*
     * Getter returns the amount of open orders or matched orders of a specific user.
     * 
     * @_user is the address of the user.
     * @_openOrder refers to an open order (True) or to a matched order (False).
    */
    function getUserAmount(address _user, bool _openOrder) external onlyLogicContract view returns(uint128) {
        if (_openOrder) {
            return users[_user].openOrdersAmount;
        } else {
            return users[_user].matchedOrdersAmount;
        }
        
    }
    
    /*
     * Getter returns the ID's of the "Store of value" open orders of a specific user.
     * 
     * @_user is the address of the user.
    */
    function getUserStoreOfValueOpenOrders(address _user) external onlyLogicContract view returns(uint[]) {
        return users[_user].storeOfValueOpenOrders;
    }
    
    /*
     * Getter returns the ID's of the "Price increase bet" open orders of a specific user.
     * 
     * @_user is the address of the user.
    */
    function getUserPriceIncreaseOpenOrders(address _user) external onlyLogicContract view returns(uint[]) {
        return users[_user].increasePriceOpenOrders;
    }
    
    /*
     * Getter returns the ID's of the matched orders of a specific user.
     * 
     * @_user is the address of the user.
    */
    function getUserMatchedOrders(address _user) external onlyLogicContract view returns(uint[]) {
        return users[_user].matchedOrders;
    }
    
    /*
     * Getter returns the total amount of the orders and all orders ID's of a specific user.
     * 
     * @_user is the address of the user.
    */
    function returnUserInformation(address _user) external onlyLogicContract view returns(uint128, uint128, uint[], uint[], uint[]) {
        return(users[_user].openOrdersAmount, users[_user].matchedOrdersAmount, users[_user].storeOfValueOpenOrders, users[_user].increasePriceOpenOrders, users[_user].matchedOrders);
    }
    
    
    /*
    ********************    OPEN ORDERS    ******************** 
    * We need a struct that will keep information about open orders.
    * By using a mapping we can easy find the owner of a specific open order.
    * 
    * @user is the address of the user that owns this open order.
    * @amount is the amount that user send for this open order.
    * @openOrdersStoreOfValue keeps the information of the user for each "Store of value" open order.
    * @openOrdersPriceIncrease keeps the information of the user for each "Price increase bet" open order.
    * @storeOfValueOrders keeps the active "Store of value" open orders.
    * @increaseValueOrders keep the active "Price increase bet" open orders.
    */
    struct OpenOrder {
        address user;
        uint128 amount;
    }
    mapping(uint => OpenOrder) private openOrdersStoreOfValue;
    mapping(uint => OpenOrder) private openOrdersPriceIncrease;
    uint private openOrdersStoreOfValueIndex = 1;
    uint private openOrdersPriceIncreaseIndex = 1;
    uint[] private storeOfValueOrders;
    uint[] private increaseValueOrders;
    
    /*
     * Add a new open order from a user.
     * 
     * @_user is the address of the user who makes this new order.
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
     * @_amount is the amount that users sends to make this order.
    */
    function addOpenOrder(address _user, bool _storeOfValue, uint128 _amount) external onlyLogicContract payable returns(uint) {
        // Create a "Store of Value" open order
        if (_storeOfValue) {
            openOrdersStoreOfValue[openOrdersStoreOfValueIndex].user = _user;
            openOrdersStoreOfValue[openOrdersStoreOfValueIndex].amount = _amount;
            storeOfValueOrders.push(openOrdersStoreOfValueIndex);
            openOrdersStoreOfValueIndex += 1;
            return openOrdersStoreOfValueIndex-1;
        }
        // Create a "Price increase bet" open order
        else {
            openOrdersPriceIncrease[openOrdersPriceIncreaseIndex].user = _user;
            openOrdersPriceIncrease[openOrdersPriceIncreaseIndex].amount = _amount;
            increaseValueOrders.push(openOrdersPriceIncreaseIndex);
            openOrdersPriceIncreaseIndex += 1;
            return openOrdersPriceIncreaseIndex-1;
        }
    }
    
    /*
     * Edits the amount of an open order.
     * 
     * @_index is the ID of the order.
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
     * @_amount is the new amount for this specific order.
    */
    function editOpenOrder(uint _index, bool _storeOfValue, uint128 _amount) external onlyLogicContract payable returns(bool) {
        // Edit an existing "Store of value" order
        if (_storeOfValue) {
            openOrdersStoreOfValue[_index].amount = _amount;
            return true;
        }
        // Edit an existing "Price increase bet"  order
        else {
            openOrdersPriceIncrease[_index].amount = _amount;
            return true;
        }
        return false;
    }
    
    /*
     * Removes the first element of the array and keeps their order.
     * 
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
    */
    function removeOldestOpenOrder(bool _storeOfValue) external onlyLogicContract payable returns(bool) {
        // Remove the oldest "Store of Value" open order
        if (_storeOfValue == true) {
            if (storeOfValueOrders.length == 0) {
                return true;
            }
            for (uint i=0; i<storeOfValueOrders.length-1; i++) { 
                storeOfValueOrders[i] = storeOfValueOrders[i+1];
            }
            storeOfValueOrders.length--;
            return true;
        }
        // Remove the oldest "Price increase bet" open order
        else if (_storeOfValue == false) {
            if (increaseValueOrders.length == 0) {
                return true;
            }
            for (uint j=0; j<increaseValueOrders.length-1; j++) { 
                increaseValueOrders[j] = increaseValueOrders[j+1];
            }
            increaseValueOrders.length--;
            return true;
        }
        return false;
    }
    
    /*
     * Removes a spefific order ID.
     * 
     * @_orderId is the ID of the order we want to remove.
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
    */
    function removeSpecificOpenOrder(uint _orderId, bool _storeOfValue) external onlyLogicContract payable returns(bool) {
        uint index = storeOfValueOrders.length;
        // Remove from "Store of Value" open orders
        if (_storeOfValue == true) {
            if (storeOfValueOrders[storeOfValueOrders.length-1] == _orderId) {
                storeOfValueOrders.length--;
                return true;
            }
            // Find index
            index = storeOfValueOrders.length;
            for (uint i=0; i<storeOfValueOrders.length; i++) { 
                if (storeOfValueOrders[i] == _orderId) {
                    index = i;
                    break;
                }
            }
            // Check if element exists
            if (index == storeOfValueOrders.length) {
                return false;
            }
            for (i=index; i<storeOfValueOrders.length-1; i++) {
                storeOfValueOrders[i] = storeOfValueOrders[i+1];
            }
            storeOfValueOrders.length--;
            return true;
        }
        // Remove from "Price increase bet" open orders
        else {
            if (increaseValueOrders[increaseValueOrders.length-1] == _orderId) {
                increaseValueOrders.length--;
                return true;
            }
            // Find index
            index = increaseValueOrders.length;
            for (uint j=0; j<increaseValueOrders.length; j++) { 
                if (increaseValueOrders[j] == _orderId) {
                    index = j;
                    break;
                }
            }
            // Check if element exists
            if (index == increaseValueOrders.length) {
                return false;
            }
            for (j=index; j<increaseValueOrders.length-1; j++) {
                increaseValueOrders[j] ==increaseValueOrders[j+1];
            }
            increaseValueOrders.length--;
            return true;
        }
        return false;
    }
    
    /*
     * Getter returns the information of a specific open order.
     * 
     * @_orderId is the ID of the order we are looking for.
     * @_storeOfValue refers to a "Store of value" order (True) or to a "Price increase bet" order (False).
    */
    function getUserOpenOrder(uint _orderId, bool _storeOfValue) external onlyLogicContract view returns(address, uint128) {
        bool check;
        if (_storeOfValue) {
            for (uint i=0; i<storeOfValueOrders.length; i++) { 
                if (storeOfValueOrders[i] == _orderId) {
                    check = true;
                }
            }
            require(check);
            return (openOrdersStoreOfValue[_orderId].user, openOrdersStoreOfValue[_orderId].amount);
        } else {
            for (uint j=0; j<increaseValueOrders.length; j++) { 
                if (increaseValueOrders[j] == _orderId) {
                    check = true;
                }
            }
            require(check);
            return (openOrdersPriceIncrease[_orderId].user, openOrdersPriceIncrease[_orderId].amount);
        }
    }
    
    /*
     * Getter of "Store of value" active orders.
    */
    function getStoreOfValueOrders() external onlyLogicContract view returns(uint[]) {
        return storeOfValueOrders;
    }
    
    /*
     * Getter of "Increase value bet" active orders.
    */
    function getIncreaseValueOrders() external onlyLogicContract view returns(uint[]) {
        return increaseValueOrders;
    }
    
    /*
     * Getter information of a specific "Store of valu" order.
     *
     * @_orderId is the ID of the order.
    */
    function getStoreOfValueOrderInformation(uint _orderId) external onlyLogicContract view returns(address, uint128) {
        return (openOrdersStoreOfValue[_orderId].user, openOrdersStoreOfValue[_orderId].amount);
    }
    
    /*
     * Getter information of a specific "Increase value bet" order.
     *
     * @_orderId is the ID of the order.
    */
    function getPriceIncreaseOrderInformation(uint _orderId) external onlyLogicContract view returns(address, uint128) {
        return (openOrdersPriceIncrease[_orderId].user, openOrdersPriceIncrease[_orderId].amount);
    }
    
    /*
     * Setter for changing the amount of a specific "Store of value" order.
     * 
     * @_orderId is the ID of the order.
     * @_amount is the new amount.
    */
    function decraseStoreOfValueBySpecificAmount(uint _orderId, uint128 _amount) external onlyLogicContract payable returns(bool) {
        openOrdersStoreOfValue[_orderId].amount -= _amount;
        
        return true;
    }
    
    /*
     * Setter for changing the amount of a specific "Increase price bet" order.
     * 
     * @_orderId is the ID of the order.
     * @_amount is the new amount.
    */
    function decraseIncreasePriceBySpecificAmount(uint _orderId, uint128 _amount) external onlyLogicContract payable returns(bool) {
        openOrdersPriceIncrease[_orderId].amount -= _amount;
        
        return true;
    }

    /*
    ********************    MATCHED ORDERS    ******************** 
    * We need a struct that will keep information about matched orders.
    * By using a mapping we can easy find information about a specific matched order.
    * 
    * @userA is the address of the user with the "Store of value" position.
    * @userB is the address of the user with the "Price increase bet" position.
    * @amount is the amount of each user that send for this order (so, total amount = amount * 2).
    * @etherPrice is the Ether price when this matched order was made.
    * @active indicates if an order is active (True) or not (False).
    */
    struct MatchedOrder {
        address userA;
        address userB;
        uint128 amount;
        uint32 etherPrice;
        bool active;
    }
    mapping(uint => MatchedOrder) private matchedOrders;
    
    /*
     * Add a new matched order.
     * 
     * @_userA is the address of the user with the "Store of value" position.
     * @_userB is the address of the user with the "Price increase bet" position.
     * @_amount is the amount of each user that send for this order (so, total amount = amount * 2).
     * @_etherPrice is the Ether price when this matched order was made.
    */
    function addMatchedOrder(address _userA, address _userB, uint128 _amount, uint32 _etherPrice) external onlyLogicContract payable returns(uint) {
        // Get a unique number and check that is available
        uint nonce = 0;
        uint orderId = uint(keccak256(abi.encodePacked(_userA,_userB,block.number,nonce)));
        while (matchedOrders[orderId].active == true) {
            nonce += 1;
            orderId = uint(keccak256(abi.encodePacked(_userA,_userB,block.number,nonce)));
        }
        
        // Add new elements
        matchedOrders[orderId].userA = _userA;
        matchedOrders[orderId].userB = _userB;
        matchedOrders[orderId].amount = _amount;
        matchedOrders[orderId].etherPrice = _etherPrice;
        matchedOrders[orderId].active = true;
        
        // Return the new matched order ID.
        return orderId;
    }
    
    /*
     * This function sends money to a specific user, during an order cancelation or completion.
     * 
     * @_user is the address of the user we want to send the money to.
     * @_amount is the amount we want to send.
    */
    function returnMoney(address _user, uint128 _amount) external onlyLogicContract payable returns(bool) {
        _user.transfer(uint256(_amount));
        return true;
    }
    
    /*
     * Setter marks an order's ID as unused (canceled or completed order), so we can handle possible hash function collisions.
     * 
     * @_orderId is the ID of the matched order.
    */
    function disableMatchedOrder(uint _orderId) external onlyLogicContract payable returns(bool) {
        matchedOrders[_orderId].active = false;
        return true;
    }
    
    /*
     * Getter returns all the information about a specific matched order.
     * 
     * @_orderId is the ID of the matched order.
    */
    function getMatchedOrder(uint _orderId) external onlyLogicContract view returns(address, address, uint128, uint32, bool) {
        return(matchedOrders[_orderId].userA, matchedOrders[_orderId].userB, matchedOrders[_orderId].amount, matchedOrders[_orderId].etherPrice, matchedOrders[_orderId].active);
    }
    
    
    /*
    ********************    OTHER FUNCTIONS    ******************** 
    */
    
    /*
     * This function removes a given array element. It doesn't keep the sorting of the array.
     * 
     * @_array is the input array
     * @_id is the element value (not the index) that we want to remove. 
    */
    function deleteArrayElement(uint[] storage _array, uint _id) private returns(bool) {
        uint _index;
        if (_array.length == 1 || _array[_array.length-1] == _id) {
            _array.length--;
            return true;
        } else {
            for (uint i=0; i<_array.length; i++) {
                if (_array[i] == _id) {
                    _index = i;
                    _array[_index] = _array[_array.length-1];
                    _array.length--;
                    return true;
                }
            }
        }
        return false;
    }
    
    /*
     * Getter returns the amount of a specific Store of Value open order.
     * 
     * @_orderId is the ID of the order we want.
    */
    function getStoreOfValueAmountByID(uint _orderId) public view returns(uint128) {
        require(msg.sender == openOrdersStoreOfValue[_orderId].user);
        return openOrdersStoreOfValue[_orderId].amount;
    }
    
    /*
     * Getter returns the amount of a specific Price Increase bet open order.
     * 
     * @_orderId is the ID of the order we want.
    */
    function getIncreasePriceAmountByID(uint _orderId) public view returns(uint128) {
        require(msg.sender == openOrdersPriceIncrease[_orderId].user);
        return openOrdersPriceIncrease[_orderId].amount;
    }
    
    /*
     * Getter returns the amount of a specific matched order.
     * 
     * @_orderId is the ID of the order we want.
    */
    function getMatchedOrderInformationtByID(uint _orderId) public view returns(uint128, bool, uint32) {
        require(msg.sender == matchedOrders[_orderId].userA || msg.sender == matchedOrders[_orderId].userB);
        if (msg.sender == matchedOrders[_orderId].userA) {
            return (matchedOrders[_orderId].amount, true, matchedOrders[_orderId].etherPrice);
        } else {
            return (matchedOrders[_orderId].amount, false, matchedOrders[_orderId].etherPrice);
        }
    }
}