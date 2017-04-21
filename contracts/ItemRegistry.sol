pragma solidity 0.4.8;

contract ItemRegistry {
    address public admin;
    uint256 public commission;
    mapping(uint256=>Item) items;
    uint256 public NumberOfItems;

    mapping(address=>bool) validators;
    uint256 public NumberOfValidators;

    mapping(uint256=>Escrow) escrows;
    
    modifier AdminOnly()
    {
        if (msg.sender != admin) throw;
        _;
    }
    
    

    //destruct and send balance to owner
    function kill()
            public
    {
        if (msg.sender == admin)
        selfdestruct(admin);
    }

    //just in case
    function()
    {
        throw;
    }

    event ItemRegistered(uint256 id, address ownerAddress,string description,string date, uint price, bool forSale);
    event ItemDeleted(uint256 id);
    event ItemValidated(uint256 id, string serialNumber, address validationCompany, bool isValid, string reason);
    event ItemTransferred(uint256 id, address fromOwner, address toOwner, uint256 price);

  
 

    event SaleStart(uint256 itemId, address buyer);


    struct Escrow {
        address seller;
        address buyer;
        bool sellerApprove;
        bool buyerApprove;
        uint256 amount;
        bool init;
    }

 

    //proof of item authenticity
    struct Authenticity {
        string serialNumber;
        address validationCompany;
        string validationDate;
        bool    isValid;
        string reason;
    }


    //item
    struct Item {
        uint256 id;
        address owner;
        Authenticity authenticity;
        string origin;
        string description;
        string issueDate;
        uint256 price;
        bool forSale;
        bool deleted;
    }

    //constructor
    function ItemRegistry()
    {
        admin = msg.sender;
        NumberOfItems=0;
        NumberOfValidators = 0;
    }

    function RegisterValidator(address companyAddress)
        public
        AdminOnly
    {
        validators[companyAddress] = true;
        NumberOfValidators+=1;
    }



    //get item validity
    function IsItemValid(uint256 id)
        public
        constant
        returns(bool isValid)
    {

        return items[id].authenticity.isValid;

    }





        //get item
    function ReturnItem(uint256 id)
        public
        returns (   address owner,
                    string description,
                    string origin,
                    string issueDate,
                    uint price,
                    bool forSale,
                    bool deleted )
    {
        if (NumberOfItems==0) throw;
            Item memory item = items[id];
                return (item.owner,
                        item.description,
                        item.origin,
                        item.issueDate,
                        item.price,
                        item.forSale,
                        item.deleted);



    }

            //get item
    function ReturnItemAuthenticity(uint256 id)
        public
        returns (string serialNumber,
                    address validationCompanyAddress,
                    string validationDate,
                    bool    isValid,
                    string reason )
    {
        if (NumberOfItems==0) throw;
            Item memory item = items[id];
                return (
                        item.authenticity.serialNumber,
                        item.authenticity.validationCompany,
                        item.authenticity.validationDate,
                        item.authenticity.isValid,
                        item.authenticity.reason
                        );


    }

    //create item - executed by collector
    function RegisterItem(string description,string origin,string issueDate, uint price, bool forSale )
        public
    {
        Item memory newItem;
        newItem.id = NumberOfItems;

        //assumption - all new items are registered
        //as invalid by default
        //and need to be validated
        newItem.authenticity.isValid = false;
        newItem.authenticity.reason="pending validation";
        newItem.description=description;
        //assumption - registered by owner
        newItem.owner = msg.sender;
        newItem.origin = origin;

        newItem.issueDate=issueDate;

        newItem.price = price;
        newItem.forSale = forSale;
        newItem.deleted = false;

        items[NumberOfItems] = newItem;
        ItemRegistered(newItem.id,msg.sender,description,issueDate,price,forSale);
        NumberOfItems+=1;
    }

     //delete item - admin only
    function DeleteItem(uint256 id)
        public
    {
        if (msg.sender != admin) throw;
        if (NumberOfItems==0) throw;

                items[id].deleted = true;
                ItemDeleted(id);

    }

    function StartSale(uint256 itemId)
        public
        payable
        returns (uint256) {

        if(escrows[itemId].init == true) throw;
        Item memory item = items[itemId];
        if (item.price>msg.value) throw;

        Escrow memory e;
        e.seller = item.owner;
        e.buyer = msg.sender;
        e.amount = msg.value;
        e.sellerApprove=false;
        e.buyerApprove = false;
        e.init=true;
        escrows[itemId] = e;

        SaleStart(itemId, e.buyer);

    return itemId;
}

  function ApproveSale(uint256 itemId)
  {
     if(escrows[itemId].init == false) throw;

    if(msg.sender == escrows[itemId].buyer)
    escrows[itemId].buyerApprove = true;
    else if(msg.sender == escrows[itemId].seller)
    escrows[itemId].sellerApprove = true;
    if(escrows[itemId].sellerApprove && escrows[itemId].buyerApprove)
    FinishSale(itemId);
  }

  function AbortSale(uint256 itemId){
     if(escrows[itemId].init == false) throw;

      if(msg.sender == escrows[itemId].buyer)
      escrows[itemId].buyerApprove = false;
      else if (msg.sender == escrows[itemId].seller)
      escrows[itemId].sellerApprove = false;
      if(!escrows[itemId].sellerApprove && !escrows[itemId].buyerApprove)
      CancelSale(itemId);
  }

    function CancelSale(uint256 itemId)
        private
        returns (bool Success) {

        if(escrows[itemId].init == false) throw;
        //return money to buyer
        if(escrows[itemId].buyer.send(escrows[itemId].amount) == true)
        {
            delete escrows[itemId];
            return true;
        }

    return false;
}

    function FinishSale(uint256 itemId)
        private
        returns (bool Success) {

        if(escrows[itemId].init == false) throw;
        //send  money to seller minus comission
        uint amount= escrows[itemId].amount - commission;
        if(escrows[itemId].seller.send(amount) == true && admin.send(commission) == true)
        {

            TransferOwnership(itemId,escrows[itemId].buyer);
            delete escrows[itemId];
            return true;

        }

    return false;
}


     //sell item
    function TransferOwnership(uint256 id, address newOwnerAddress)
        private
    {

        items[id].owner = newOwnerAddress;
        ItemTransferred(id, items[id].owner,newOwnerAddress,items[id].price);
        
    }

    //see if Validator is in our system
    function FindValidator(address tryAddress)
        private
        returns(bool isSuccess)
    {
        if (NumberOfValidators==0) throw;
       
           return validators[tryAddress];
           
    }



    //validate item - executed by validator
    function ValidateItem(uint256 id, string serialNumber, string validationDate, bool isValid, string reason )
        public
        returns(bool isSuccess)
    {
        if (NumberOfItems==0) throw;
        address validatorAddress = msg.sender;
        if (FindValidator(validatorAddress)==false) throw;

                items[id].authenticity.isValid = isValid;
                items[id].authenticity.serialNumber = serialNumber;
                items[id].authenticity.validationCompany = validatorAddress;
                items[id].authenticity.validationDate = validationDate;
                items[id].authenticity.reason = reason;
                ItemValidated(id, serialNumber, validatorAddress,isValid,reason);


        return false;
    }




}