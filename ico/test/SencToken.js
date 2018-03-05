const { BigNumber } = web3;
const should = require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();
const WhiteListed = artifacts.require("../contracts/SencToken.sol");

contract("SencToken",addresses => {

})