// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
