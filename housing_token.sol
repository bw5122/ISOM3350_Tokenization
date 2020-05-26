pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";
import './Owned.sol';
import './ERC20_interface.sol';

/**
* Original code from:
* @title Real Estate Token
* @author Alberto Cuesta Canada
* @notice Implements a real estate tokenization contract with 
* revenue distribution.
* 
* Modifications:
* 14/05/2020 by David, Yeung Ngo Yan
*/
contract RealEstateToken is ERC20_interface, Owned {
   using SafeMath for uint256;

   /**
    * A data structure to encapsulate the agreement of selling tokens to another stakeholders
    */
   struct ApproveTokenSales {
       uint256 priceInEther;
       uint256 amountToBuy;
   }
   
   /**
    * A list of the address of the stakeholders / the investors involved.
    */
   address[] internal stakeholders;

   /**
    * A mapping from the address to the amount of ether the address has earned but yet to withdraw. 
    */
   mapping(address => uint256) internal revenues;

   /**
    * The amount of ether that has not been distributed to each of the stakeholders. 
    * The amount could refer to the rent received from renting out the real estate used in the contract.
    */
   uint256 internal accumulated;
   
   /**
    * A total supply of tokens, set on construct.
    */
   uint256 private _totalSupply;
   
   /**
    * A mapping from an address to the number of tokens owned. 
    */
   mapping(address => uint256) balance;
   
   /**
    * A mapping to store all the approved sales of tokens to another stakeholder 
    */
   mapping(address => mapping(address => ApproveTokenSales)) approvedSales;

   /**
    * The constructor of the token.
    * The owner of the contract (i.e. the real estate portfolio) is set to be the address who deploy the contract.
    * The owner have to specify the total supply of tokens.
    * The owner is assigned all the tokens at the beginning.
    * The owner is added to the stakeholder list (assuming the owner is also one of the investor).
    * 
    * @param _supply The amount of tokens to create on construction.
    */
   constructor(uint256 _supply)
       public
   {
       _totalSupply = _supply;
       address owner = msg.sender;
       balance[owner] = balance[owner].add(_supply);
       addStakeholder(owner);
   }

   /**
    * A function to receive ether payment to the contract.
    */
   function pay_to_contract()
       external
       payable
   {
       accumulated += msg.value;
   }
   
   /**
    * A function that returns the total supply of tokens, defined in the ERC20 interface. 
    */
   function totalSupply()
       public
       view
       override
       returns (uint256)
   {
       return _totalSupply;
   }
   
   /**
    * A function which returns the amount of real estate token owned by an address, defined in the ERC20 interface.
    * 
    * @param tokenOwner The address to get its tokens owned.
    */
   function balanceOf(address tokenOwner) 
       public 
       view 
       override
       returns (uint256 token_owned) 
   {
        return balance[tokenOwner];
   }
   
   /**
    * A function to transfer real estate token to another address. 
    * Can only send to the addresses in the stakeholder list.
    * 
    * @param to The address to receive the tokens.
    * @param tokens The amount of RealEstateTokens to send.
    */
   function transfer(address to, uint tokens) 
       public 
       override
       returns (bool success) 
   {
       (bool isStakeholder, ) = isStakeholder(to);
       require(isStakeholder);
       require(msg.sender != address(0), "ERC20: token send from zero address");
       require(to != address(0), "ERC20: token send to zero address");
       balance[msg.sender] = balance[msg.sender].sub(tokens, "ERC20: transfer amount exceeds balance");
       balance[to] = balance[to].add(tokens);
       return true;
   }

   /**
    * A function to check if an address is a stakeholder involved in the contract.
    * Returns whether the address is a stakeholder, and if so its position in the stakeholders array.
    * 
    * @param _address The address to verify.
    */
   function isStakeholder(address _address)
       public
       view
       returns(bool, uint256)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   /**
    * A function to add a new address to the stakeholder list. 
    * 
    * @param _stakeholder The address to be added.
    */
   function addStakeholder(address _stakeholder)
       public
       onlyOwner
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if (!_isStakeholder) stakeholders.push(_stakeholder);
   }

   /**
    * A function to remove an address from the stakeholder list. do nothing if the address is not in the list.
    * 
    * @param _stakeholder The address to remove.
    */
   function removeStakeholder(address _stakeholder)
       public
       onlyOwner
   {
       (bool _isStakeholder, uint256 s) 
           = isStakeholder(_stakeholder);
       if (_isStakeholder){
           stakeholders[s] 
               = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }

   /**
    * A function to get the proportion of tokens held by an address.
    * 
    * @param _stakeholder The stakeholder to calculate share for.
    */
   function getShare(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return balanceOf(_stakeholder) / totalSupply();
   }
   
   /**
    * A function that approves future token selling action to a target address with a fixed amount of ether from the message sender.
    * 
    * @param target: the address buying the tokens
    * @param amountInEther: the amount of price in ether they agreed on
    * @param amountInToken: the amount of token they agree to transact
    */
   function approveSales(address target, uint256 amountInEther, uint256 amountInToken)
      public
   {
       (bool TargetIsStakeholder, ) = isStakeholder(msg.sender);
       require(TargetIsStakeholder, "The address to buy token from is not yet a stakeholder");
       (bool ReceiverIsStakeholder, ) = isStakeholder(target);
       require(ReceiverIsStakeholder, "Receiver is not yet a stakeholder, please inform owner to add a new address in stakeholder list");
       require(msg.sender != address(0), "ERC20: token selling from zero address");
       require(target != address(0), "ERC20: tokens selling to zero address");
       require(balance[msg.sender] >= amountInToken, "Insufficient token in the your wallet");
       
       ApproveTokenSales storage trans;
       trans.priceInEther = amountInEther;
       trans.amountToBuy = amountInToken;
       approvedSales[msg.sender][target] = trans;
       
       // reset the approval
       ApproveTokenSales storage zero_trans;
       trans.priceInEther = 0;
       trans.amountToBuy = 0;
       approvedSales[msg.sender][target] = zero_trans;
   }
   
   /**
    * A function to buy tokens from another stakeholder according to the approval
    * 
    * @param target the address of the account to buy from
    * @param amount the amount of tokens to purchase
    */
   function buyFrom(address target, uint256 amount)
       public
       payable
   {
       ApproveTokenSales storage trans = approvedSales[target][msg.sender];
       require(msg.value >= trans.priceInEther, "The amount paid is not enough");
       require(amount <= trans.amountToBuy, "The amount of token purchasing is larger than the approved value");
       
       revenues[target] += msg.value;
       balance[target] -= amount;
       balance[msg.sender] += amount;
       
       
   }

   /**
    * A function to distribute the accumulated amount to all the stakeholders by their share.
    * Only the owner of the contract can execute this function.
    */
   function distribute()
       public
       onlyOwner
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];
           uint256 revenue 
               = address(this).balance * getShare(stakeholder);
           accumulated = accumulated.sub(revenue);
           revenues[stakeholder] 
               = revenues[stakeholder].add(revenue);
       }
   }

   /**
    * A function to withdraw the distributed amount to their own account.
    * Withdraw the amount of the message sender. 
    */
   function withdraw()
       public
   {
       uint256 revenue = revenues[msg.sender];
       revenues[msg.sender] = 0;
       address payable recipient = msg.sender;
       recipient.transfer(revenue);
   }
}