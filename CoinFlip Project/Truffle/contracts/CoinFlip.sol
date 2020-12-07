import "./Ownable.sol";
pragma solidity 0.5.16;

//Comments

contract CoinFlip is Ownable {

  //keep track of balance
  uint public balance;

  //Minimum and maximum bets
  uint constant minBet = 0.1 ether;
  uint constant maxBet = 2 ether;

  //Win & Lose event
  event win(uint amountWon);
  event lose(uint amountLost);

  //Pseudo-randomness function
  function random() public view returns (uint) {
    return now % 2;
  }

  //Place bet on side of coin
  function placeBet (uint side) external payable returns (string memory error){
    uint amount = msg.value;
    require (amount >= minBet && amount <= maxBet);

    //check whether contract has funds to process this bet
    require(balance > (amount * 2));

    if (side == 0) {
      uint result = random();

      if (result == 0) {
        uint amountWon = amount *2;
        balance -= amount;
        msg.sender.transfer(amountWon);
        emit win(amountWon);
      } else if (result == 1) {
        balance += amount;
        emit lose(amount);
      } else {
        return ('something went wrong.');
      }
    }


    if (side == 1) {
      uint result = random();

      if (result == 1) {
        uint amountWon = amount *2;
        balance -= amount;
        msg.sender.transfer(amountWon);
        emit win(amountWon);
      } else if (result == 0) {
        balance += amount;
        emit lose(amount);
      } else {
          return ('something went wrong');
      }
    }
  }

  //Fallback function to add funds to the Contract
  function addFunds() external payable {
    balance += msg.value;
  }

  //Funds withdrawal to cover costs of CoinFlip
  function withdrawFunds(uint amount) external onlyOwner returns (uint) {
    require(amount <= balance, 'Not enough funds.');
    balance -= amount;
    msg.sender.transfer(amount);
    return amount;
  }

  // Contract may be destroyed by Owner
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

}
