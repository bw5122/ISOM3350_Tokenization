pragma solidity ^0.6.0;
/**
 * An interface to define contract ownership, get insights from ERC20 interface.
 */
contract Owned {
    /**
     * Owner variable, store the address of the owner.
     */
    address public owner;

    /**
     * Constructor to set the owner variable.
     */
    constructor() internal {
        owner = msg.sender;
    }

    /**
     * Define a new keyword 'onlyOwner' which only allows the owner to execute a function.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * A function to transfer ownership to another address.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Owned: new owner is the zero address");
        owner = _newOwner;
    }
    
    /**
     * A function to discard the ownership, voiding the contract 
     * as the onlyOwner function cannot be executed after executing this function.
     */
    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}