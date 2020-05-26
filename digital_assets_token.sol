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
contract DigitalAssetToken is ERC20_interface, Owned {
   using SafeMath for uint256;
   
   struct assetInfo {
    address owner;
    string assetType;
    string assetName;
    string assetIntro;
    address[] stakeholders;
    uint256 numStakeHolders;
    uint256 accumulated;
    uint256  _totalSupply;
    uint256 priceOfToken;
    mapping(address => uint256)  revenues;    //A mapping from the address to the amount of ether the address has earned but yet to withdraw. 
    mapping(address => uint256) balance; //A mapping from an address to the number of tokens owned. 
   }

    mapping(uint256 => assetInfo) assets;
    uint256[] public assetsIds;

    function registerAssets(string memory assetType, string memory assetName, string memory assetIntro, uint256 accumulated, 
    uint256 _totalSupply, uint256 priceOfToken) public returns(string memory){
        uint256 numAssets = assetsIds.length;
        assetInfo storage newAssets = assets[numAssets+1];
        newAssets.assetName = assetName;
        newAssets.assetIntro = assetIntro;
        newAssets.owner = msg.sender;
        newAssets.assetType = assetType;
        newAssets.accumulated = accumulated;
        newAssets._totalSupply = _totalSupply;
        newAssets.priceOfToken = priceOfToken;
        newAssets.numStakeHolders = 0;
        newAssets.balance[msg.sender].add(_totalSupply); //give all tokens to the owner
    //    addStakeholder(numAssets+1, msg.sender);
        assetsIds.push(numAssets+1);
        return ("your asset is registered successfully!");
    }

    /**
    * return information of a single asset by asset id
    */
    function getAssetById(uint256 id) public view returns (address, string memory, string memory, string memory, uint256,uint256,uint256){
        assetInfo storage a = assets[id];
       return (a.owner, a.assetType, a.assetName, a.assetIntro, a.accumulated, a._totalSupply, a.priceOfToken);
    }
    
    /**
    * TODO: return the list of assets available for trade
    */
    function getAssetList(uint256 assetId) public view returns (string memory, string memory){
        string memory list;
        for (uint256 s =0; s<assets.length; s+=1){
            list = list + assets[s] +" ";
        }
        return ("list: ", list);
    }

   /**
    * TODO: add support to multi-class asset
    *  A function to receive ether payment to the contract.
    */
   function pay_to_contract(uint256 assetId)
       external
       payable
   {
      assetInfo storage a = assets[assetId];
      a.accumulated += msg.value;
   }
   
   /**
    * TODO: add support to multi-class asset
    *   A function that returns the total supply of tokens, defined in the ERC20 interface. 
    */
   function totalSupply(uint256 assetId)
       public
       view
       override
       returns (uint256)
   {
       assetInfo storage a = assets[assetId];
       return a._totalSupply;
   }
   
   /**
    * TODO: add multi-class support
    * A function which returns the amount of real estate token owned by an address, defined in the ERC20 interface.
    * 
    * @param tokenOwner The address to get its tokens owned.
    */
   function balanceOf(uint256 assetId, address tokenOwner) 
       public 
       view 
       override
       returns (uint256 token_owned) 
   {
       assetInfo storage a = assets[assetId];
       return a.balance[tokenOwner];
   }
   
   /**
    * TODO: add multi-class support
    * 
    * A function to transfer real estate token to another address. 
    * Can only send to the addresses in the stakeholder list.
    * 
    * @param to The address to receive the tokens.
    * @param tokens The amount of RealEstateTokens to send.
    */
   function transfer(uint256 assetId, address to, uint tokens) 
       public 
       override
       returns (bool success) 
   {
      (bool isStakeholder, ) = isStakeholder(assetId, to);
      require(isStakeholder);
      require(msg.sender != address(0), "ERC20: approve from the zero address");
      require(to != address(0), "ERC20: approve to the zero address");
      assetInfo storage a = assets[assetId];
      a.balance[msg.sender] = a.balance[msg.sender].sub(tokens, "ERC20: transfer amount exceeds balance");
      a.balance[to] = a.balance[to].add(tokens);
      return true;
   }

   /**
    * TODO: add multi-class support
    * A function to check if an address is a stakeholders involved i the contract.
    * Returns whether the address is a stakeholder, and if so its position in the stakeholders array.
    * 
    * @param _address The address to verify.
    */
   function isStakeholder(uint256 assetId, address _address)
       public
       view
       returns(bool, uint256)
   {
        assetInfo storage a = assets[assetId];
           for (uint256 s = 0; s < a.stakeholders.length; s += 1){
             if (_address == a.stakeholders[s]) return (true, s);
           }
        return (false, 0);
   }

   /**
    * TODO: add multi-class support
    * A function to add a new address to the stakeholder list. 
    * 
    * @param _stakeholder The address to be added.
    */
   function addStakeholder(uint256 assetId, address _stakeholder)
       public
       onlyOwner
   {
        assetInfo storage a = assets[assetId];
        (bool _isStakeholder, ) = isStakeholder(assetId, _stakeholder);
        if (!_isStakeholder){
           // tempSH.push(_stakeholder);
           a.stakeholders.push(_stakeholder);
           a.numStakeHolders = a.numStakeHolders + 1;
        }
   }

   /**
    * TODO: add multi-class support
    * A function to remove an address from the stakeholder list. do nothing if the address is not in the list.
    * 
    * @param _stakeholder The address to remove.
    */
   function removeStakeholder(uint256 assetId, address _stakeholder)
       public
       onlyOwner
   {
       assetInfo storage a = assets[assetId];
       (bool _isStakeholder, uint256 s) 
           = isStakeholder(assetId, _stakeholder);
       if (_isStakeholder){
           a.stakeholders[s] 
               = a.stakeholders[a.stakeholders.length - 1];
           a.stakeholders.pop();
       }
   }

   /**
    * TODO: add multi-class support
    * A function to get the proportion of tokens hold by an address.
    * 
    * @param _stakeholder The stakeholder to calculate share for.
    */
   function getShare(uint256 assetId, address _stakeholder)
       public
       view
       returns(uint256)
   {
       return balanceOf(assetId,_stakeholder) / totalSupply(assetId);
   }

   /**
    * TODO: add multi-class support
    * A function to distribute the accumulated amount to all the stakeholders by their share.
    * Only the owner of the contract can execute this function.
    */
   function distribute(uint256 assetId)
       public
       onlyOwner
   {
       assetInfo storage a = assets[assetId];
       for (uint256 s = 0; s < a.stakeholders.length; s += 1){
           address stakeholder = a.stakeholders[s];
           uint256 revenue 
               = address(this).balance * getShare(assetId, stakeholder);
           a.accumulated = a.accumulated.sub(revenue);
           a.revenues[stakeholder] 
               = a.revenues[stakeholder].add(revenue);
       }
   }

   /**
    * TODO: add multi-class support
    * A function to withdraw the distributed amount to their own account.
    * Withdraw the amount of the message sender. 
    */
   function withdraw(uint256 assetId)
       public
   {
       assetInfo storage a = assets[assetId];
       uint256 revenue = a.revenues[msg.sender];
       a.revenues[msg.sender] = 0;
       address payable recipient = msg.sender;
       recipient.transfer(revenue);
   }
   
   
}
