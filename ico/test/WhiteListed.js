const { BigNumber } = web3;
const should = require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();
const WhiteListed = artifacts.require("../contracts/WhiteListed.sol");

contract("WhiteListed", addresses => {
    const owner = addresses[0];
    const operator1 = addresses[1];
    const operator2 = addresses[2];
    const user1 = addresses[3];
    const user2 = addresses[4];

    let whiteListed
    beforeEach('setup contract for whitelisting', async () => {
      whiteListed = await WhiteListed.new();
    });
    
    it('has an owner', async () => {
      assert.equal(await whiteListed.owner(), addresses[0])
    });

    it('can add whitelist', async () => {
        await whiteListed.addWhiteListed([user1,user2],[1,2],[3,4]);
         let isAdded = await whiteListed.isWhiteListed(user1);
         isAdded.should.equal(true);
         let count = await whiteListed.getWhiteListCount();
         count.should.bignumber.equal(2);
    });

    it('can find user1', async () => {

        await whiteListed.addWhiteListed([user1,user2],[1,2],[3,4]);
         let isAdded = await whiteListed.isWhiteListed(user1);
         isAdded.should.equal(true);
         let count = await whiteListed.getWhiteListCount();
         count.should.bignumber.equal(2);
        
        let batchNumber = await whiteListed.getBatchNumber(user1);
        let allocated = await whiteListed.getAllocated(user1);
        batchNumber.should.bignumber.equal(1);
        allocated.should.bignumber.equal(3);
    });

    it('can delete whitelist', async () => {
        await whiteListed.addWhiteListed([user1,user2],[1,2],[3,4]);
         let isAdded = await whiteListed.isWhiteListed(user1);
         isAdded.should.equal(true);
         let count = await whiteListed.getWhiteListCount();
         count.should.bignumber.equal(2);

         await whiteListed.removeWhiteListed(0, user1);
         
         (await whiteListed.isWhiteListed(user1)).should.equal(false);
         let isAdded2 = await whiteListed.isWhiteListed(user1);
         isAdded2.should.equal(false);
         count = await whiteListed.getWhiteListCount();
         count.should.bignumber.equal(1);
    });

    it('can set a primary operator', async() => {
        await whiteListed.setPrimaryOperator(operator1);
        let isOperator = await whiteListed.isPrimaryOperator(operator1);
        isOperator.should.equal(true);
    });

    it('can add a secondary operator', async () => {
        await whiteListed.setSecondaryOperator(operator2);
        let isOperator = await whiteListed.isSecondaryOperator(operator2);
        isOperator.should.equal(true);
    });

});