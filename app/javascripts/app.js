

var itemRegistry = ItemRegistry.deployed();
  
    console.log("The contract:", itemRegistry);
let Owners = {}

window.RegisterItem = function(Item) {
   let description = $("#description").val();
  let origin = $("#origin").val();
  let issueDate = $("#issueDate").val();
  let price = $("#price").val();
  let forSale = $("#forSale").val();

    $("#msg").html("Item Registered")
  //$("#owner").val("");
  

  /* ItemRegistry.deployed() returns an instance of the contract. Every call
   * in Truffle returns a promise which is why we have used then()
   * everywhere we have a transaction call
   */
  ItemRegistry.deployed().then(function(contractInstance) {
  	//var t = Math.ceil(Math.random() * 10) -1;
  	
  	var addr = web3.eth.accounts[0];
    contractInstance.RegisterItem(description,origin,issueDate, price, forSale, {gas: 1400000, from: addr}).then(function() {
      
      return contractInstance.NumberOfItems.call().then(function(v) {
         $("#msg").html("You registered" + v.toString() + " items");
         populateItems();
      });
    });
  });
}

/* Instead of hardcoding the Owners hash, we now fetch the Owner list from
 * the blockchain and populate the array. Once we fetch the Owners, we setup the
 * table in the UI with all the Owners and the votes they have received.
 */

function populateItems() {
	$("#owner-rows").empty();
  ItemRegistry.deployed().then(function(contractInstance) {

    contractInstance.NumberOfItems.call().then(function(NumberOfItems) {


    	//alert(owners.length);
      for(let i=0;  i < NumberOfItems; i++) {
      	   contractInstance.ReturnItem.call(i).then(function(owner,
                    description,
                    origin,
                    issueDate,
                    price,
                    forSale,
                    deleted) {

        /* We store the Owner names as bytes32 on the blockchain. We use the
         * handy toUtf8 method to convert from bytes32 to string
         */
         $("#owner-rows").append("<tr><td>" + owner +  " "  + description + "</td></tr>");
        //Owners[i] = own;
            });
      }

    });
  });
}


$( document ).ready(function() {

   populateItems();

});