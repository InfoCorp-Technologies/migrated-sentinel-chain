const { BigNumber } = web3;
const should = require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();
const SencTokenSale = artifacts.require("../contracts/SencTokenSale.sol");
const WhiteListed = artifacts.require("../contracts/WhiteListed.sol");

contract("SencTokenSale", addresses => {
  
  const owner = addresses[0];

  const batchStartTimes = [1518981490,1518981490];
  const endTime = 1528981490;
  const ethUsdRate =  1;
  const agTechWallet = addresses[1];
  const foundingTeamWallet = addresses[2];
  const earlySupportersWallet = addresses[3];
  const presaleWei = 12345;
  const presaleAddresses = [addresses[4], addresses[5]];
  const presaleAmounts = [1,2];
  const treasuryWallet = addresses[6];
  const tokenIssuer = addresses[0];
  const user1 = addresses[7];
  const user2 = addresses[8];
  const presaleWallet = addresses[9];

  let wListed;
  let sencTokenSale;
  /**
   * Contract SencTokenSale initialization
   */
  beforeEach('setup whielistedbasic contract', async() => {
    wListed = await WhiteListed.new();
  });

    // uint256[] _batchStartTimes, 
    // uint256 _endTime, 
    // uint256 ethusdRate,
    // uint256 _presaleWei,              
    // WhiteListedBasic _whiteListed, 
    // address _agTechWallet, 
    // address _foundingTeamWallet, 
    // address _earlySupportersWallet, 
    // address _treasuryWallet,
    // address _presaleWallet,
    // address _tokenIssuer) 

  beforeEach('setup contract for senc token sale', async () => {
    let wlAddr = await wListed.address;
    sencTokenSale = await SencTokenSale.new(batchStartTimes, 
                              endTime, 
                              ethUsdRate, 
                              presaleWei,
                              wlAddr,
                              agTechWallet,
                              foundingTeamWallet,
                              earlySupportersWallet,
                              treasuryWallet,
                              presaleWallet,
                              tokenIssuer);
                              
  });

  it('crowdsale shouldn\'t  have finalized', async() => {
    let isFinalized = await sencTokenSale.isFinalized()
    isFinalized.should.equal(false);
  });

  it('should have SencToken initialized', async() => {
    (await sencTokenSale.token() != undefined).should.equal(true);
  });

  it('crowdsale shouldn\'t have ended', async() => {
    (await sencTokenSale.hasEnded()).should.equal(false);
  });

  it('crowdsale shouldn\'t be paused', async() => {
    (await sencTokenSale.paused()).should.equal(false);
  });

  it('Some batch is active', async() => {
    let batchLength = batchStartTimes.length;
    let batchActive = await sencTokenSale.batchActive(); 
    (batchLength <= batchActive).should.equal(true);
  });

});