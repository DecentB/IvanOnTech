const coinFlip = artifacts.require('CoinFlip');
const truffleAssert = require('truffle-assertions');

contract('CoinFlip', async function(accounts) {

  let instance;

  before(async function(){
    instance = await coinFlip.deployed();
    await instance.addFunds({value: web3.utils.toWei('20', 'ether')})
  })

  it('should not place bet less than Minimum', async function () {
    await truffleAssert.reverts(instance.placeBet(0, {from: accounts[1], value: web3.utils.toWei('0.05', 'ether')}));
  })
  it('should not place bet more than Maximum', async function () {
    await truffleAssert.reverts(instance.placeBet(0, {from: accounts[1], value: web3.utils.toWei('2.5', 'ether')}));
  })
  it('should place bet if within limits', async function () {
    await truffleAssert.passes(instance.placeBet(0, {from: accounts[1], value: web3.utils.toWei('1.5', 'ether')}));
  })
  it('Non-owner should not be able to withdraw Funds', async function() {
    await truffleAssert.reverts(instance.withdrawFunds(web3.utils.toWei('1', 'ether'),{from: accounts[1]}));
  })
  it('Owner should be able to withdraw Funds', async function() {
    await truffleAssert.passes(instance.withdrawFunds(web3.utils.toWei('1', 'ether'),{from: accounts[0]}));
  })
  it('Owners wallet balance should increase after withdraw Funds', async function() {
    let blockchainBalanceBefore = parseFloat(await web3.eth.getBalance(accounts[0]));
    await instance.withdrawFunds(web3.utils.toWei('1', 'ether'));
    let blockchainBalanceAfter = parseFloat(await web3.eth.getBalance(accounts[0]));
    assert(blockchainBalanceAfter > blockchainBalanceBefore);
  })
  it('Internal balance should decrease when withdraw Funds', async function() {
    let balanceBefore = await instance.balance();
    let floatBalance = await parseFloat(balanceBefore);
    await instance.withdrawFunds(web3.utils.toWei('1', 'ether'));
    let balanceAfter = await instance.balance();
    let floatBalanceAfter = await parseFloat(balanceAfter);
    assert(floatBalanceAfter == (floatBalance - web3.utils.toWei('1', 'ether')));
  })
})
