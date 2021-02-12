let contractInstance;
let web3;

$(document).ready(async function() {
  $('#withdrawWinnings_button').hide();

  const provider = await detectEthereumProvider();
  if (provider) {
  web3 = new Web3(provider);
  await window.ethereum.enable().then(function(accounts){
    contractInstance = new web3.eth.Contract(abi, '0x40B8cd00AeF5b9EBD4a3eCBc4D80639b0AeeBd16', {from: accounts[0]});
    console.log(contractInstance);
    _getLatestBet();
  })
  } else {
  console.log('Please install MetaMask!');
  }

  $('#heads_button').click(() => _placeBet(1));
  $('#tails_button').click(() => _placeBet(2));
  $('#checkWinnings_button').click(() => _getGamblerWinningsOwed());
  $('#withdrawWinnings_button').click(() => _gamblerWithdrawFunds());
})

// User can place Bet entering amount and selecting Heads or Tails
function _placeBet(side){
  const _value = $('#amount_input').val();

  let config = {
    value: web3.utils.toWei(_value.toString(),'ether')
  };

  contractInstance.methods.placeBet(side).send(config)
    .on('transactionHash', function(hash){
      $('#transaction_output').text(hash);
      $('#lastResult_output').text('Pending');
      console.log(hash);
      listenForEvent();
    })
    .on('confirmation', function(confirmationNr){
      console.log(confirmationNr);
    })
    .on('receipt', function(receipt){
      console.log(receipt.events);
    })
}

// Find out result of the users latest Bet
async function _getLatestBet() {
    let latestBet = await contractInstance.methods.getLatestBet().call()
    if (latestBet) {
      $('#lastResult_output').text(latestBet)
      if (latestBet === 'Pending') {
        listenForEvent();
      }
    } else {
      $('#lastResult_output').text('No information available')
    }
}

// Find amount of winnings owed to user
async function _getGamblerWinningsOwed() {
  let winningsOwed = await contractInstance.methods.getGamblerWinningsOwed().call();
  let winningsOwedEther = await web3.utils.fromWei(winningsOwed, 'ether')

  if (winningsOwedEther > 0) {
    $('#winningsAvailable_output').text(winningsOwedEther);
    $('#withdrawWinnings_button').show()
  } else {
    $('#winningsAvailable_output').text('No winnings owed to you.');
  }
}

// User can withdraw their winnings
async function _gamblerWithdrawFunds() {
  contractInstance.methods.gamblerWithdrawFunds().send()
  .on('transactionHash', function(hash){
    $('#transaction_output').text(hash);
    console.log(hash);
  })
  .on('confirmation', function(confirmationNr){
    console.log(confirmationNr);
  })
  .on('receipt', function(receipt){
    console.log(receipt.events);
  })
}

// Listen for events to see result of the users open Bet
async function listenForEvent() {
  const accounts = await web3.eth.getAccounts()
  contractInstance.events.gameResult()
  .on('data', (event) => {
    if (event.returnValues.gambler == accounts[0]) {
    $('#lastResult_output').text(event.returnValues.result)
    console.log(event.returnValues);
    }
  })
  .on('error', (error) => {
    console.log(error);
  })
}
