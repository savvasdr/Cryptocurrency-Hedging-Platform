/*
      ███████╗████████╗██╗  ██╗███████╗██████╗ ███████╗██╗   ██╗███╗   ███╗
      ██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝██║   ██║████╗ ████║
      █████╗     ██║   ███████║█████╗  ██████╔╝█████╗  ██║   ██║██╔████╔██║
      ██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██║╚██╔╝██║
      ███████╗   ██║   ██║  ██║███████╗██║  ██║███████╗╚██████╔╝██║ ╚═╝ ██║
      ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝
 ___                                                     _                       _   
(  _`\                                                  ( )_                    ( )_ 
| |_) ) _ __   _          _   _       ___    _     ___  | ,_) _ __   _ _    ___ | ,_)
| ,__/'( '__)/'_`\ (`\/')( ) ( )    /'___) /'_`\ /' _ `\| |  ( '__)/'_` ) /'___)| |  
| |    | |  ( (_) ) >  < | (_) |   ( (___ ( (_) )| ( ) || |_ | |  ( (_| |( (___ | |_ 
(_)    (_)  `\___/'(_/\_)`\__, |   `\____)`\___/'(_) (_)`\__)(_)  `\__,_)`\____)`\__)
                         ( )_| |                                                     
                         `\___/'                                                     
*/
pragma solidity ^0.4.20;    // Tested on version 0.4.25


contract ProxyContract {
    
    
    /*
    ********************    CONTRACT INFORMATION    ******************** 
     * A basic property of smart contracts, are their immutability. 
     *    
     * We will use this proxy contract to create an upgradable smart contract.
     * All users will call this contract and proxy contract will 
     * forward them to the right address of the Hedging Platform contract.
     * 
     * The contract that contains the data will have a constant address,
     * and the logic contract will be able to change address in 
     * a case of upgrade.
    */


    /*
     * @_owner is the creator of this contract.
     * @_dataContract is the address of the dataContract.
     * @_logicContract is the address of the logicContract;
    */
    address owner;
    address dataContract;
    address logicContract;
    address autoMatch;
    
    /*
     * The constructor will set the owner of the contract.
    */
    constructor() public {
        owner = msg.sender;
    }
    
    /*
     * Only the owner can change the address.
    */
    modifier isOwner() {
        assert(msg.sender == owner);
        _;
    }
    
    /*
     * Setter of the Data contract address.
    */
    function setDataContractAddress(address _dataContract) public isOwner payable {
        dataContract = _dataContract;
    }
    
    /*
     * Getter of the Data contract address.
    */
    function getDataContractAddress() public view returns (address) {
        return dataContract;
    }
    
    /*
     * Setter of the Logic contract address.
    */
    function setLogicContractAddress(address _logicContract) public isOwner payable {
        logicContract = _logicContract;
    }
    
    /*
     * Getter of the Logic contract address.
    */
    function getLogicContractAddress() public view returns (address) {
        return logicContract;
    }
    
    /*
     * Setter of the AutoMatch contract address.
    */
    function setAutoMatchContractAddress(address _autoMatch) public isOwner payable {
        autoMatch = _autoMatch;
    }
    
    /*
     * Getter of the AutoMatch contract address.
    */
    function getAutoMatchContractAddress() public view returns (address) {
        return autoMatch;
    }
}