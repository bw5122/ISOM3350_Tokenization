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
   
     /**
    * A data structure to encapsulate the agreement of selling tokens to another stakeholders
    */
   struct ApproveTokenSales {
       uint256 priceInEther;
       uint256 amountToBuy;
   }
   
   /**
    * A data structure to contains all information of the asset 
    */
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
    mapping(address => mapping(address => ApproveTokenSales)) approvedSales; //A mapping to store all the approved sales of tokens to another stakeholder
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
        newAssets.stakeholders.push(msg.sender);
        newAssets.numStakeHolders = 1;
        newAssets.balance[newAssets.owner]=_totalSupply; //give all tokens to the owner
    //    addStakeholder(numAssets+1, msg.sender);
        assetsIds.push(numAssets+1);
        return ("asset is added successfully");
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
    function getAssetList() public view returns (string memory){
        string memory accumulated="";
        for (uint256 s = 0; s<assetsIds.length; s+=1){
            uint256 id = assetsIds[s];
            accumulated = string(abi.encodePacked(accumulated, "-----------Asset ID: ",uintToString(id), "+++Name: ", assets[id].assetName, ",Type: ", assets[id].assetType, ",Intro: ",assets[id].assetIntro, ",Price of Token: ",uintToString(assets[id].priceOfToken),"-----------"));
        }
        return (accumulated);
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
   {
        assetInfo storage a = assets[assetId];
        require(a.owner == msg.sender, "invalid action by non-owner of asset");
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
   {
       assetInfo storage a = assets[assetId];
       require(a.owner == msg.sender, "invalid action by non-owner of asset");
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
    * A function to get the proportion of tokens hold by an address, expressed in percentage.
    * 
    * @param _stakeholder The stakeholder to calculate share for.
    */
   function getShare(uint256 assetId, address _stakeholder)
       public
       view
       returns(uint256)
   {
       return balanceOf(assetId,_stakeholder)*100 / totalSupply(assetId);
   }

   /**
    * A function that approves future token selling action to a target address with a fixed amount of ether from the message sender.
    * 
    * @param target: the address buying the tokens
    * @param amountInEther: the amount of price in ether they agreed on
    * @param amountInToken: the amount of token they agree to transact
    */
   function approveSales(uint256 assetId, address target, uint256 amountInEther, uint256 amountInToken)
      public
   {
       assetInfo storage a = assets[assetId];
       (bool TargetIsStakeholder, ) = isStakeholder(assetId, msg.sender);
       require(TargetIsStakeholder, "The address to buy token from is not yet a stakeholder");
       (bool ReceiverIsStakeholder, ) = isStakeholder(assetId, target);
       require(ReceiverIsStakeholder, "Receiver is not yet a stakeholder, please inform owner to add a new address in stakeholder list");
       require(msg.sender != address(0), "ERC20: token selling from zero address");
       require(target != address(0), "ERC20: tokens selling to zero address");
       require(a.balance[msg.sender] >= amountInToken, "Insufficient token in the your wallet");
       
       ApproveTokenSales storage trans;
       trans.priceInEther = amountInEther;
       trans.amountToBuy = amountInToken;
       a.approvedSales[msg.sender][target] = trans;
       
       // reset the approval
       ApproveTokenSales storage zero_trans;
       trans.priceInEther = 0;
       trans.amountToBuy = 0;
       a.approvedSales[msg.sender][target] = zero_trans;
   }
   
   /**
    * A function to buy tokens from another stakeholder according to the approval
    * 
    * @param target the address of the account to buy from
    * @param amount the amount of tokens to purchase
    */
   function buyFrom(uint256 assetId, address target, uint256 amount)
       public
       payable
   {
       assetInfo storage a = assets[assetId];
       ApproveTokenSales storage trans = a.approvedSales[target][msg.sender];
       require(msg.value >= trans.priceInEther, "The amount paid is not enough");
       require(amount <= trans.amountToBuy, "The amount of token purchasing is larger than the approved value");
       
       a.revenues[target] += msg.value;
       a.balance[target] -= amount;
       a.balance[msg.sender] += amount;
   }
   
   /**
    * TODO: add multi-class support
    * A function to distribute the accumulated amount to all the stakeholders by their share.
    * Only the owner of the contract can execute this function.
    */
   function distribute(uint256 assetId)
       public
   {
       assetInfo storage a = assets[assetId];
       require(a.owner == msg.sender, "invalid action by non-owner of asset");
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
   
    function uintToString(uint v) public view returns (string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }
   
}