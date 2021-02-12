// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ProvableAPI.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
pragma solidity 0.6.12;

//Comments

contract CoinFlip is Ownable, usingProvable {

  // Use openzeppelin SafeMath library
  using SafeMath for uint;

  // Keep track of balance
  uint public balance;

  // Funds that are locked in unsettled potentially winning bets. Prevents contract from
  // committing to bets it cannot pay out.
  uint public lockedInBets;

  // Keep track of Winnings that have not yet been withdrawn. Prevents contract
  // from committing to bets it cannot pay out.
  uint public winningsOwed;

  // Minimum and maximum bets
  uint constant minBet = 0.1 ether;
  uint constant maxBet = 2 ether;

  // Win & Lose event
  event gameResult(address gambler, string result, uint amount);

  // Provable Random Number Events
  event newBetPlaced(bytes32 queryId);
  event logNewProvableQuery(string description);
  event generatedRandomNumber(uint256 randomNumber);
  event provableVerificationFailed(string description);
  event somethingWentWrong(address gambler);

  // A structure representing a single bet.
  struct Bet {
    address payable gambler;
    uint amount;
    uint side;
    uint result;
  }

  // A structure for a Gambler's latest Bet
  struct Latest {
    bytes32 queryId;
    bool unsettled;
    string result;
  }


  // Mapping to all active & settled bets.
  mapping (bytes32 => Bet) public bets;

  // Mapping to keep track of each gambler's latest Bet.
  mapping (address => Latest) public latestBet;

  // Mapping to keep track of gambler balance.
  mapping (address => uint) public gamblerBalance;

  // Insert a new Bet into the bets mapping.
  function insertBet(Bet memory newBet, bytes32 _id) private returns (address){
      bets[_id] = newBet;
      return bets[_id].gambler;
  }

  function insertLatest(Latest memory newLatest, address gambler) private {
      latestBet[gambler] = newLatest;
  }

  function random() payable public returns (bytes32) {
    uint256 QUERY_EXECUTION_DELAY = 0; // NOTE: The datasource currently does not support delays > 0!
    uint256 GAS_FOR_CALLBACK = 200000;
    uint256 NUM_RANDOM_BYTES_REQUESTED = 1;
    bytes32 queryId = provable_newRandomDSQuery(
        QUERY_EXECUTION_DELAY,
        NUM_RANDOM_BYTES_REQUESTED,
        GAS_FOR_CALLBACK
    );
    balance = SafeMath.sub(balance, GAS_FOR_CALLBACK);
    emit logNewProvableQuery("Provable query was sent, standing by for the answer...");
    return queryId;
  }

  // Place bet on side of coin
  function placeBet (uint _side) payable external {
    // Check if gambler has existing bets open
    require(latestBet[msg.sender].unsettled == false, 'Still has an open Bet');
    // Require bet to be with the range of value
    require(msg.value >= minBet && msg.value <= maxBet);
    // Check whether contract has funds to process this bet
    require(balance - (winningsOwed + (lockedInBets * 2)) > (msg.value  * 2));

    // This creates a new Bet
    Bet memory newBet;
    newBet.gambler = msg.sender;
    newBet.amount = msg.value;
    newBet.side = _side;

    bytes32 _queryId = random();

    // This creates a latest Bet
    Latest memory newLatest;
    newLatest.queryId = _queryId;
    newLatest.unsettled = true;
    newLatest.result = 'Pending';

    insertBet(newBet, _queryId);
    insertLatest(newLatest, msg.sender);
    balance = SafeMath.add(balance, msg.value);
    lockedInBets += msg.value;

    emit newBetPlaced(_queryId);
  }

  // Function to close state of open Bets after being settled.
  function closeOpenBet(address gambler, uint amount) private {
    latestBet[gambler].unsettled = false;
    lockedInBets -= amount;
  }

  //Function to run to update the bet upon receiving Random Number
  function settleBet (bytes32 _id) private {
    uint amount = bets[_id].amount;
    address payable gambler = bets[_id].gambler;
    uint side = bets[_id].side;
    uint result = bets[_id].result;

    if (side == 1) {
      if (result == 1) {
        latestBet[gambler].result = 'Win';
        closeOpenBet(gambler, amount);
        uint amountWon = SafeMath.mul(amount,2);
        winningsOwed = SafeMath.add(winningsOwed, amountWon);
        gamblerBalance[gambler] += amountWon;
        emit gameResult(gambler, 'Win', amountWon);
      } else if (result == 2) {
        latestBet[gambler].result = 'Lose';
        closeOpenBet(gambler, amount);
        emit gameResult(gambler, 'Lose', amount);
      } else {
        latestBet[gambler].result = 'Bet refunded';
        closeOpenBet(gambler, amount);
        winningsOwed = SafeMath.add(winningsOwed, amount);
        gamblerBalance[gambler] += amount;
        emit gameResult(gambler, 'Bet refunded', amount);
      }
    }

    if (side == 2) {
      if (result == 2) {
        latestBet[gambler].result = 'Win';
        closeOpenBet(gambler, amount);
        uint amountWon = SafeMath.mul(amount,2);
        winningsOwed = SafeMath.add(winningsOwed, amountWon);
        gamblerBalance[gambler] += amountWon;
        emit gameResult(gambler, 'Win', amountWon);
      } else if (result == 1) {
        latestBet[gambler].result = 'Lose';
        closeOpenBet(gambler, amount);
        emit gameResult(gambler, 'Lose', amount);
      } else {
        latestBet[gambler].result = 'Bet refunded';
        closeOpenBet(gambler, amount);
        winningsOwed = SafeMath.add(winningsOwed, amount);
        gamblerBalance[gambler] += amount;
        emit gameResult(gambler, 'Bet refunded', amount);
      }
    }
  }


  function __callback(bytes32 _queryId, string memory _result) public override {
    require(msg.sender == provable_cbAddress());

    uint256 randomNumber = (uint256(keccak256(abi.encodePacked(_result))) % 2) + 1;
    bets[_queryId].result = randomNumber;
    settleBet(_queryId);
    emit generatedRandomNumber(randomNumber);
  }

  // Function to get result of the Gambler's last game
  function getLatestBet() public view returns (string memory)  {
    return latestBet[msg.sender].result;
  }

  // Function for Gambler to withdraw funds from their winnings.
  function gamblerWithdrawFunds() public {
    require(gamblerBalance[msg.sender] > 0);
    uint amount = gamblerBalance[msg.sender];
    gamblerBalance[msg.sender] = 0;
    balance = SafeMath.sub(balance, amount);
    winningsOwed = SafeMath.sub(winningsOwed, amount);
    msg.sender.transfer(amount);
  }

  // Function for Gambler to see winnings they are able to withdraw.
  function getGamblerWinningsOwed() external view returns (uint) {
    uint _gamblerBalance = gamblerBalance[msg.sender];
    return _gamblerBalance;
  }

  //Fallback function to add funds to the Contract
  function addFunds() payable external {
    balance = SafeMath.add(balance,msg.value);
  }

  //Funds withdrawal to cover costs of CoinFlip - can only be made when there are no bets locked in
  function withdrawFunds(uint amount) external onlyOwner returns (uint) {
    require(amount <= balance - (winningsOwed + (lockedInBets * 2)), 'Not enough funds.');
    balance = SafeMath.sub(balance, amount);
    msg.sender.transfer(amount);
    return amount;
  }

  // Contract may be destroyed by Owner
  function destroy() public onlyOwner {
    require(lockedInBets == 0);
    require(winningsOwed == 0);
    selfdestruct(owner);
  }
}
