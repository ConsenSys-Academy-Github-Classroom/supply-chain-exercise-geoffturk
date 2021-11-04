// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;
  uint public skuCount;

  enum State {
    ForSale, Sold, Shipped, Received
  }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  mapping (uint => Item) public items;

  event LogForSale(uint skuCount);
  event LogSold(uint sku, address buyer);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  modifier isOwner (address _address) {
    require (msg.sender == _address, "Must be owner");
    _;
  }
  modifier isSold (uint sku) {
    require (items[sku].state == State.Sold, "Item not sold");
    _;
  }
  modifier isNotSold (uint sku) {
    require (items[sku].state != State.Sold, "Item already sold");
    _;
  }
  modifier isShipped (uint sku) {
    require (items[sku].state == State.Shipped, "Item not shipped");
    _;
  }
  modifier verifyCaller (address _address) {
    require (msg.sender == _address, "Not the correct caller");
    _;
  }
  modifier paidEnough(uint _price) {
    require(msg.value >= _price, "Not enough funds");
    _;
  }
  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  constructor() {
    owner = msg.sender;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
     name: _name,
     sku: skuCount,
     price: _price,
     state: State.ForSale,
     seller: payable(msg.sender),
     buyer: payable(address(0))
    });

    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint sku) public payable isNotSold(sku) paidEnough(items[sku].price) checkValue(sku) {
    payable(address(items[sku].seller)).transfer(items[sku].price);
    items[sku].buyer = payable(msg.sender);
    items[sku].state = State.Sold;

    emit LogSold(sku, msg.sender);
  }

  function shipItem(uint sku) public isSold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

  function receiveItem(uint sku) public isShipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
