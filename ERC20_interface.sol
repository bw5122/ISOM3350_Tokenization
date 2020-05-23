pragma solidity ^0.6.0;
/**
 * An interface to define ERC20 standards. 
 * Three functions: approve, transferFrom and allowance is not implemented as they may not be needed in the application.
 */
abstract contract ERC20_interface {
    // abstract function to get total supply of tokens.
    function totalSupply(uint256 assetId) 
		public 
		view 
		virtual
		returns (uint);

    // abstract function to get the number of tokens owned by the address.
    function balanceOf(uint256 assetId, address tokenOwner) 
		public 
		view 
		virtual
		returns (uint balance);

    // abstract function to transfer tokens to another address.
    function transfer(uint256 assetId, address to, uint tokens) 				
        public 
		virtual
		returns (bool success);
}