var web3 = new Web3(Web3.givenProvider);
let contractInstance;

$(document).ready(async function() {
  await window.ethereum.enable().then(function(accounts){
    contractInstance = new web3.eth.Contract(abi, '0xe54e0c3da71A64E558Cc0f24714CC3BE00c67935', {from: accounts[0]});
    console.log(contractInstance);
  })
  $('#heads_button').click(() => _placeBet(0));
  $('#tails_button').click(() => _placeBet(1));  
})


function _placeBet(side){
  const _value = $('#amount_input').val();
      
  let config = {
    value: web3.utils.toWei(_value.toString(),'ether')
  };
    
  contractInstance.methods.placeBet(side).send(config)
    .on('transactionHash', function(hash){
      $('#tranaction_output').text(hash);
      console.log(hash);
    })
    .on('confirmation', function(confirmationNr){
      console.log(confirmationNr);
    })
    .on('receipt', function(receipt){
      console.log(receipt.events);
      if (receipt.events.win) {
        $('#result_output').text('You Won!');
      } else if (receipt.events.lose) {
        $('#result_output').text('You Lost!');
      } else {
        console.log('no event received')
      }
    })
}

















