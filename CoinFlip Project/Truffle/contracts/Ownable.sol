pragma solidity 0.5.16;

contract Ownable {

  address payable public owner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _; //continue execution
  }

  constructor() public {
    owner = msg.sender;
  }

}
