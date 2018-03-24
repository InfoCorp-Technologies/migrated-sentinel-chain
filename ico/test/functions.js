// ETH/USD 19 Feb 2018 14:15 AEDT 927.43 from CMC and https://ethgasstation.info/
var ethPriceUSD = 844.81; // Roy 03/03/2018
var defaultGasPrice = web3.toWei(3, "gwei");

// -----------------------------------------------------------------------------
// Accounts
// -----------------------------------------------------------------------------
var accounts = [];
var accountNames = {};

addAccount(eth.accounts[0], "Account #0 - Miner");
addAccount(eth.accounts[1], "Account #1 - Contract Owner");
addAccount(eth.accounts[2], "Account #2 - Wallet");
addAccount(eth.accounts[3], "Account #3");
addAccount(eth.accounts[4], "Account #4");
addAccount(eth.accounts[5], "Account #5");
addAccount(eth.accounts[6], "Account #6");
addAccount(eth.accounts[7], "Account #7");
addAccount(eth.accounts[8], "Account #8");
addAccount(eth.accounts[9], "Account #9 - Ag Tech");
addAccount(eth.accounts[10], "Account #10 - Founding Team");
addAccount(eth.accounts[11], "Account #11 - Early Supporters");
addAccount(eth.accounts[12], "Account #12 - Treasury");
addAccount(eth.accounts[13], "Account #13 - Presale Group");
addAccount(eth.accounts[14], "Account #14 - Presale 1");
addAccount(eth.accounts[15], "Account #15 - Presale 2");
addAccount(eth.accounts[16], "Account #16 - Presale 3");
addAccount(eth.accounts[17], "Account #17 - Batch 0");
addAccount(eth.accounts[18], "Account #18 - Batch 1");
addAccount(eth.accounts[19], "Account #19 - Batch 2");
addAccount(eth.accounts[20], "Account #20 - Batch 3 - approved for 20,000 ETH");
addAccount(eth.accounts[21], "Account #21 - Batch 1 -> 2");
addAccount(eth.accounts[22], "Account #22 - Batch 2 -> 3");
addAccount(eth.accounts[23], "Account #23 - Batch 2");
addAccount(eth.accounts[24], "Account #24 - Batch 2");
addAccount(eth.accounts[25], "Account #25 - Batch 2");
addAccount(eth.accounts[26], "Account #26 - Batch 2");
addAccount(eth.accounts[27], "Account #27 - Batch 2");
addAccount(eth.accounts[28], "Account #28 - Batch 2");
addAccount(eth.accounts[29], "Account #29 - Batch 2");
addAccount(eth.accounts[30], "Account #30 - Batch 2");
addAccount(eth.accounts[31], "Account #31 - Batch 2");

var minerAccount = eth.accounts[0];
var contractOwnerAccount = eth.accounts[1];
var wallet = eth.accounts[2];
var account3 = eth.accounts[3];
var account4 = eth.accounts[4];
var account5 = eth.accounts[5];
var account6 = eth.accounts[6];
var account7 = eth.accounts[7];
var account8 = eth.accounts[8];
var walletAgTech = eth.accounts[9];
var walletFoundingTeam = eth.accounts[10];
var walletEarlySupporters = eth.accounts[11];
var walletTreasury = eth.accounts[12];
var walletPresaleGroup = eth.accounts[13];
var walletPresale1 = eth.accounts[14];
var walletPresale2 = eth.accounts[15];
var walletPresale3 = eth.accounts[16];
var account17 = eth.accounts[17];
var account18 = eth.accounts[18];
var account19 = eth.accounts[19];
var account20 = eth.accounts[20];
var account21 = eth.accounts[21];
var account22 = eth.accounts[22];
var account23 = eth.accounts[23];
var account24 = eth.accounts[24];
var account25 = eth.accounts[25];
var account26 = eth.accounts[26];
var account27 = eth.accounts[27];
var account28 = eth.accounts[28];
var account29 = eth.accounts[29];
var account30 = eth.accounts[30];
var account31 = eth.accounts[31];

var baseBlock = eth.blockNumber;

function unlockAccounts(password) {
  for (var i = 0; i < eth.accounts.length && i < accounts.length && i < 22; i++) {
    personal.unlockAccount(eth.accounts[i], password, 100000);
    if (i > 0 && eth.getBalance(eth.accounts[i]) == 0) {
      personal.sendTransaction({from: eth.accounts[0], to: eth.accounts[i], value: web3.toWei(1000000, "ether")});
    }
  }
  while (txpool.status.pending > 0) {
  }
  baseBlock = eth.blockNumber;
}

function addAccount(account, accountName) {
  accounts.push(account);
  accountNames[account] = accountName;
}


// -----------------------------------------------------------------------------
// Token Contract
// -----------------------------------------------------------------------------
var tokenContractAddress = null;
var tokenContractAbi = null;

function addTokenContractAddressAndAbi(address, tokenAbi) {
  tokenContractAddress = address;
  tokenContractAbi = tokenAbi;
}


// -----------------------------------------------------------------------------
// Account ETH and token balances
// -----------------------------------------------------------------------------
function printBalances() {
  var token = tokenContractAddress == null || tokenContractAbi == null ? null : web3.eth.contract(tokenContractAbi).at(tokenContractAddress);
  var decimals = token == null ? 18 : token.decimals();
  var i = 0;
  var totalTokenBalance = new BigNumber(0);
  console.log("RESULT:  # Account                                             EtherBalanceChange                          Token Name");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ---------------------------");
  accounts.forEach(function(e) {
    var etherBalanceBaseBlock = eth.getBalance(e, baseBlock);
    var etherBalance = web3.fromWei(eth.getBalance(e).minus(etherBalanceBaseBlock), "ether");
    var tokenBalance = token == null ? new BigNumber(0) : token.balanceOf(e).shift(-decimals);
    totalTokenBalance = totalTokenBalance.add(tokenBalance);
    console.log("RESULT: " + pad2(i) + " " + e  + " " + pad(etherBalance) + " " + padToken(tokenBalance, decimals) + " " + accountNames[e]);
    i++;
  });
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ---------------------------");
  console.log("RESULT:                                                                           " + padToken(totalTokenBalance, decimals) + " Total Token Balances");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ---------------------------");
  console.log("RESULT: ");
}

function pad2(s) {
  var o = s.toFixed(0);
  while (o.length < 2) {
    o = " " + o;
  }
  return o;
}

function pad(s) {
  var o = s.toFixed(18);
  while (o.length < 27) {
    o = " " + o;
  }
  return o;
}

function padToken(s, decimals) {
  var o = s.toFixed(decimals);
  var l = parseInt(decimals)+12;
  while (o.length < l) {
    o = " " + o;
  }
  return o;
}


// -----------------------------------------------------------------------------
// Transaction status
// -----------------------------------------------------------------------------
function printTxData(name, txId) {
  var tx = eth.getTransaction(txId);
  var txReceipt = eth.getTransactionReceipt(txId);
  var gasPrice = tx.gasPrice;
  var gasCostETH = tx.gasPrice.mul(txReceipt.gasUsed).div(1e18);
  var gasCostUSD = gasCostETH.mul(ethPriceUSD);
  var block = eth.getBlock(txReceipt.blockNumber);
  console.log("RESULT: " + name + " status=" + txReceipt.status + (txReceipt.status == 0 ? " Failure" : " Success") + " gas=" + tx.gas +
    " gasUsed=" + txReceipt.gasUsed + " costETH=" + gasCostETH + " costUSD=" + gasCostUSD +
    " @ ETH/USD=" + ethPriceUSD + " gasPrice=" + web3.fromWei(gasPrice, "gwei") + " gwei block=" + 
    txReceipt.blockNumber + " txIx=" + tx.transactionIndex + " txId=" + txId +
    " @ " + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());
}

function assertEtherBalance(account, expectedBalance) {
  var etherBalance = web3.fromWei(eth.getBalance(account), "ether");
  if (etherBalance == expectedBalance) {
    console.log("RESULT: OK " + account + " has expected balance " + expectedBalance);
  } else {
    console.log("RESULT: FAILURE " + account + " has balance " + etherBalance + " <> expected " + expectedBalance);
  }
}

function failIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 0) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 1) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function gasEqualsGasUsed(tx) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  return (gas == gasUsed);
}

function failIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: PASS " + msg);
    return 1;
  } else {
    console.log("RESULT: FAIL " + msg);
    return 0;
  }
}

function failIfGasEqualsGasUsedOrContractAddressNull(contractAddress, tx, msg) {
  if (contractAddress == null) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    var gas = eth.getTransaction(tx).gas;
    var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
    if (gas == gasUsed) {
      console.log("RESULT: FAIL " + msg);
      return 0;
    } else {
      console.log("RESULT: PASS " + msg);
      return 1;
    }
  }
}


//-----------------------------------------------------------------------------
// Wait one block
//-----------------------------------------------------------------------------
function waitOneBlock(oldCurrentBlock) {
  while (eth.blockNumber <= oldCurrentBlock) {
  }
  console.log("RESULT: Waited one block");
  console.log("RESULT: ");
  return eth.blockNumber;
}


//-----------------------------------------------------------------------------
// Pause for {x} seconds
//-----------------------------------------------------------------------------
function pause(message, addSeconds) {
  var time = new Date((parseInt(new Date().getTime()/1000) + addSeconds) * 1000);
  console.log("RESULT: Pausing '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Paused '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
//Wait until some unixTime + additional seconds
//-----------------------------------------------------------------------------
function waitUntil(message, unixTime, addSeconds) {
  var t = parseInt(unixTime) + parseInt(addSeconds) + parseInt(1);
  var time = new Date(t * 1000);
  console.log("RESULT: Waiting until '" + message + "' at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Waited until '" + message + "' at at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
//Wait until some block
//-----------------------------------------------------------------------------
function waitUntilBlock(message, block, addBlocks) {
  var b = parseInt(block) + parseInt(addBlocks);
  console.log("RESULT: Waiting until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  while (eth.blockNumber <= b) {
  }
  console.log("RESULT: Waited until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
// Token Contract
//-----------------------------------------------------------------------------
var tokenFromBlock = 0;
function printTokenContractDetails() {
  console.log("RESULT: tokenContractAddress=" + tokenContractAddress);
  if (tokenContractAddress != null && tokenContractAbi != null) {
    var contract = eth.contract(tokenContractAbi).at(tokenContractAddress);
    var decimals = contract.decimals();
    console.log("RESULT: token.owner=" + contract.owner());
    // console.log("RESULT: token.pendingOwner=" + contract.pendingOwner());
    console.log("RESULT: token.symbol=" + contract.symbol());
    console.log("RESULT: token.name=" + contract.name());
    console.log("RESULT: token.decimals=" + decimals);
    console.log("RESULT: token.totalSupply=" + contract.totalSupply().shift(-decimals));
    console.log("RESULT: token.mintingFinished=" + contract.mintingFinished());
    console.log("RESULT: token.paused=" + contract.paused());

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var mintEvents = contract.Mint({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    mintEvents.watch(function (error, result) {
      console.log("RESULT: Mint " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    mintEvents.stopWatching();

    var mintFinishedEvents = contract.MintFinished({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    mintFinishedEvents.watch(function (error, result) {
      console.log("RESULT: MintFinished " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    mintFinishedEvents.stopWatching();

    var approvalEvents = contract.Approval({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: Approval " + i++ + " #" + result.blockNumber + " owner=" + result.args.owner +
        " spender=" + result.args.spender + " value=" + result.args.value.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: Transfer " + i++ + " #" + result.blockNumber + ": from=" + result.args.from + " to=" + result.args.to +
        " value=" + result.args.value.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Crowdsale Contract
// -----------------------------------------------------------------------------
var crowdsaleContractAddress = null;
var crowdsaleContractAbi = null;

function addCrowdsaleContractAddressAndAbi(address, crowdsaleAbi) {
  crowdsaleContractAddress = address;
  crowdsaleContractAbi = crowdsaleAbi;
}

var crowdsaleFromBlock = 0;
function printCrowdsaleContractDetails() {
  console.log("RESULT: crowdsaleContractAddress=" + crowdsaleContractAddress);
  if (crowdsaleContractAddress != null && crowdsaleContractAbi != null) {
    var contract = eth.contract(crowdsaleContractAbi).at(crowdsaleContractAddress);
    var i;
    var decimals = contract.DECIMALS();
    console.log("RESULT: crowdsale.owner=" + contract.owner());
    console.log("RESULT: crowdsale.TOKEN_FOUNDINGTEAM=" + contract.TOKEN_FOUNDINGTEAM() + " " + contract.TOKEN_FOUNDINGTEAM().shift(-decimals) + " SENC");
    console.log("RESULT: crowdsale.TOKEN_EARLYSUPPORTERS=" + contract.TOKEN_EARLYSUPPORTERS() + " " + contract.TOKEN_EARLYSUPPORTERS().shift(-decimals) + " SENC");
    console.log("RESULT: crowdsale.TOKEN_PRESALE=" + contract.TOKEN_PRESALE() + " " + contract.TOKEN_PRESALE().shift(-decimals) + " SENC");
    console.log("RESULT: crowdsale.TOKEN_TREASURY=" + contract.TOKEN_TREASURY() + " " + + contract.TOKEN_TREASURY().shift(-decimals) + " SENC");
    console.log("RESULT: crowdsale.paused=" + contract.paused());
    console.log("RESULT: crowdsale.getBatchStartTimesLength=" + contract.getBatchStartTimesLength());
    for (i = 0; i < contract.getBatchStartTimesLength(); i++) {
      var batchStartTime = contract.batchStartTimes(i);
      console.log("RESULT: crowdsale.getBatchStartTime[" + i + "]=" + batchStartTime + " " + new Date(batchStartTime * 1000).toUTCString() + " " + new Date(batchStartTime * 1000).toString());
    }
    console.log("RESULT: crowdsale.isFinalized=" + contract.isFinalized());
    console.log("RESULT: crowdsale.token=" + contract.token());
    console.log("RESULT: crowdsale.endTime=" + contract.endTime() + " " + new Date(contract.endTime() * 1000).toUTCString());
    console.log("RESULT: crowdsale.startTime=" + contract.startTime() + " " + new Date(contract.startTime() * 1000).toUTCString());
    console.log("RESULT: crowdsale.agTechWallet=" + contract.agTechWallet());
    console.log("RESULT: crowdsale.usdPerMEth=" + contract.usdPerMEth() + " " + contract.usdPerMEth().shift(-6));
    console.log("RESULT: crowdsale.publicSaleSencPerMEth=" + contract.publicSaleSencPerMEth() + " " + contract.publicSaleSencPerMEth().shift(-6));
    console.log("RESULT: crowdsale.privateSaleSencPerMEth=" + contract.privateSaleSencPerMEth() + " " + contract.privateSaleSencPerMEth().shift(-6));
    console.log("RESULT: crowdsale.weiRaised=" + contract.weiRaised() + " " + contract.weiRaised().shift(-18));
    console.log("RESULT: crowdsale.whiteListed=" + contract.whiteListed());

    var latestBlock = eth.blockNumber;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var pauseEvents = contract.Pause({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    pauseEvents.watch(function (error, result) {
      console.log("RESULT: Pause " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    pauseEvents.stopWatching();

    var unpauseEvents = contract.Unpause({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    unpauseEvents.watch(function (error, result) {
      console.log("RESULT: Unpause " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    unpauseEvents.stopWatching();

    var finalizedEvents = contract.Finalized({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    finalizedEvents.watch(function (error, result) {
      console.log("RESULT: Finalized " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    finalizedEvents.stopWatching();

    var tokenPurchaseEvents = contract.TokenPurchase({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    tokenPurchaseEvents.watch(function (error, result) {
      console.log("RESULT: TokenPurchase " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    tokenPurchaseEvents.stopWatching();

    var tokenPresaleEvents = contract.TokenPresale({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    tokenPresaleEvents.watch(function (error, result) {
      console.log("RESULT: TokenPresale " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    tokenPresaleEvents.stopWatching();

    var tokenFoundingTeamEvents = contract.TokenFoundingTeam({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    tokenFoundingTeamEvents.watch(function (error, result) {
      console.log("RESULT: TokenFoundingTeam " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    tokenFoundingTeamEvents.stopWatching();

    var tokenTreasuryEvents = contract.TokenTreasury({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    tokenTreasuryEvents.watch(function (error, result) {
      console.log("RESULT: TokenTreasury " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    tokenTreasuryEvents.stopWatching();

    var earlySupportersEvents = contract.EarlySupporters({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    earlySupportersEvents.watch(function (error, result) {
      console.log("RESULT: EarlySupporters " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    earlySupportersEvents.stopWatching();

    crowdsaleFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Whitelist Contract
// -----------------------------------------------------------------------------
var whitelistContractAddress = null;
var whitelistContractAbi = null;

function addWhitelistContractAddressAndAbi(address, whitelistAbi) {
  whitelistContractAddress = address;
  whitelistContractAbi = whitelistAbi;
}

var whitelistFromBlock = 0;
function printWhitelistContractDetails() {
  console.log("RESULT: whitelistContractAddress=" + whitelistContractAddress);
  if (whitelistContractAddress != null && whitelistContractAbi != null) {
    var contract = eth.contract(whitelistContractAbi).at(whitelistContractAddress);
    console.log("RESULT: whitelist.owner=" + contract.owner());
    console.log("RESULT: whitelist.primaryOperator=" + contract.primaryOperator());
    console.log("RESULT: whitelist.secondaryOperator=" + contract.secondaryOperator());
    console.log("RESULT: whitelist.getWhiteListCount=" + contract.getWhiteListCount());
    console.log("RESULT: whitelist.getAllocated(account17)=" + contract.getAllocated(account17) + " " + contract.getAllocated(account17).shift(-18) + " ETH");
    console.log("RESULT: whitelist.getBatchNumber(account17)=" + contract.getBatchNumber(account17));
    console.log("RESULT: whitelist.isWhiteListed(account17)=" + contract.isWhiteListed(account17));
    console.log("RESULT: whitelist.batchMap(account17)=" + JSON.stringify(contract.batchMap(account17)));
    console.log("RESULT: whitelist.batchMap(account18)=" + JSON.stringify(contract.batchMap(account18)));
    console.log("RESULT: whitelist.batchMap(account19)=" + JSON.stringify(contract.batchMap(account19)));
    console.log("RESULT: whitelist.batchMap(account20)=" + JSON.stringify(contract.batchMap(account20)));
    console.log("RESULT: whitelist.batchMap(account21)=" + JSON.stringify(contract.batchMap(account21)));
    console.log("RESULT: whitelist.batchMap(account22)=" + JSON.stringify(contract.batchMap(account22)));
    console.log("RESULT: whitelist.batchMap(account30)=" + JSON.stringify(contract.batchMap(account30)));

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: whitelistFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var whitelistedEvents = contract.Whitelisted({}, { fromBlock: whitelistFromBlock, toBlock: latestBlock });
    i = 0;
    whitelistedEvents.watch(function (error, result) {
      console.log("RESULT: Whitelisted " + i++ + " #" + result.blockNumber +
        " addr=" + result.args.addr + " isWhiteListed=" + result.args.isWhitelisted +
        " batch=" + result.args.batch + " weiAllocation=" + result.args.weiAllocation + " " + result.args.weiAllocation.shift(-18));
    });
    whitelistedEvents.stopWatching();

    whitelistFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Vesting Contract
// -----------------------------------------------------------------------------
var vestingContractAddress = null;
var vestingContractAbi = null;

function addVestingContractAddressAndAbi(address, vestingAbi) {
  vestingContractAddress = address;
  vestingContractAbi = vestingAbi;
}

var vestingFromBlock = 0;
function printVestingContractDetails() {
  console.log("RESULT: vestingContractAddress=" + vestingContractAddress);
  if (vestingContractAddress != null && vestingContractAbi != null) {
    var contract = eth.contract(vestingContractAbi).at(vestingContractAddress);
    console.log("RESULT: vesting.owner=" + contract.owner());
    // console.log("RESULT: vesting.addresses(0)=" + contract.addresses(0));
    console.log("RESULT: vesting.primaryOperator=" + contract.primaryOperator());
    console.log("RESULT: vesting.secondaryOperator=" + contract.secondaryOperator());
    console.log("RESULT: vesting.token=" + contract.token());
    console.log("RESULT: vesting.started=" + contract.started());
    console.log("RESULT: vesting.startTimestamp=" + contract.startTimestamp() + " " + new Date(contract.startTimestamp() * 1000).toUTCString() + " " + new Date(contract.startTimestamp() * 1000).toString());
    console.log("RESULT: vesting.totalTokens=" + contract.totalTokens() + " " + contract.totalTokens().shift(-18));
    console.log("RESULT: vesting.entries(foundingTeam 0xaaaa)=" + JSON.stringify(contract.entries(walletFoundingTeam)));
    console.log("RESULT: vesting.entries(earlySupporters 0xabba)=" + JSON.stringify(contract.entries(walletEarlySupporters)));
    console.log("RESULT: vesting.entries(presaleGroup 0xadda)=" + JSON.stringify(contract.entries(walletPresaleGroup)));
    console.log("RESULT: vesting.entries(presale1 0xaeea)=" + JSON.stringify(contract.entries(walletPresale1)));
    console.log("RESULT: vesting.entries(presale2 0xaffa)=" + JSON.stringify(contract.entries(walletPresale2)));
    console.log("RESULT: vesting.entries(presale3 0xb00b)=" + JSON.stringify(contract.entries(walletPresale3)));

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: vestingFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var newEntryEvents = contract.NewEntry({}, { fromBlock: vestingFromBlock, toBlock: latestBlock });
    i = 0;
    newEntryEvents.watch(function (error, result) {
      console.log("RESULT: NewEntry " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    newEntryEvents.stopWatching();

    vestingFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Generate Summary JSON
// -----------------------------------------------------------------------------
function generateSummaryJSON() {
  console.log("JSONSUMMARY: {");
  if (crowdsaleContractAddress != null && crowdsaleContractAbi != null) {
    var contract = eth.contract(crowdsaleContractAbi).at(crowdsaleContractAddress);
    var blockNumber = eth.blockNumber;
    var timestamp = eth.getBlock(blockNumber).timestamp;
    console.log("JSONSUMMARY:   \"blockNumber\": " + blockNumber + ",");
    console.log("JSONSUMMARY:   \"blockTimestamp\": " + timestamp + ",");
    console.log("JSONSUMMARY:   \"blockTimestampString\": \"" + new Date(timestamp * 1000).toUTCString() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleContractAddress\": \"" + crowdsaleContractAddress + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleContractOwnerAddress\": \"" + contract.owner() + "\",");
    console.log("JSONSUMMARY:   \"tokenContractAddress\": \"" + contract.bttsToken() + "\",");
    console.log("JSONSUMMARY:   \"tokenContractDecimals\": " + contract.TOKEN_DECIMALS() + ",");
    console.log("JSONSUMMARY:   \"crowdsaleWalletAddress\": \"" + contract.wallet() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleTeamWalletAddress\": \"" + contract.teamWallet() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleTeamPercent\": " + contract.TEAM_PERCENT_GZE() + ",");
    console.log("JSONSUMMARY:   \"bonusListContractAddress\": \"" + contract.bonusList() + "\",");
    console.log("JSONSUMMARY:   \"tier1Bonus\": " + contract.TIER1_BONUS() + ",");
    console.log("JSONSUMMARY:   \"tier2Bonus\": " + contract.TIER2_BONUS() + ",");
    console.log("JSONSUMMARY:   \"tier3Bonus\": " + contract.TIER3_BONUS() + ",");
    var startDate = contract.START_DATE();
    // BK TODO - Remove for production
    startDate = 1512921600;
    var endDate = contract.endDate();
    // BK TODO - Remove for production
    endDate = 1513872000;
    console.log("JSONSUMMARY:   \"crowdsaleStart\": " + startDate + ",");
    console.log("JSONSUMMARY:   \"crowdsaleStartString\": \"" + new Date(startDate * 1000).toUTCString() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleEnd\": " + endDate + ",");
    console.log("JSONSUMMARY:   \"crowdsaleEndString\": \"" + new Date(endDate * 1000).toUTCString() + "\",");
    console.log("JSONSUMMARY:   \"usdPerEther\": " + contract.usdPerKEther().shift(-3) + ",");
    console.log("JSONSUMMARY:   \"usdPerGze\": " + contract.USD_CENT_PER_GZE().shift(-2) + ",");
    console.log("JSONSUMMARY:   \"gzePerEth\": " + contract.gzePerEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"capInUsd\": " + contract.CAP_USD() + ",");
    console.log("JSONSUMMARY:   \"capInEth\": " + contract.capEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"minimumContributionEth\": " + contract.MIN_CONTRIBUTION_ETH().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"contributedEth\": " + contract.contributedEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"contributedUsd\": " + contract.contributedUsd() + ",");
    console.log("JSONSUMMARY:   \"generatedGze\": " + contract.generatedGze().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"lockedAccountThresholdUsd\": " + contract.lockedAccountThresholdUsd() + ",");
    console.log("JSONSUMMARY:   \"lockedAccountThresholdEth\": " + contract.lockedAccountThresholdEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"precommitmentAdjusted\": " + contract.precommitmentAdjusted() + ",");
    console.log("JSONSUMMARY:   \"finalised\": " + contract.finalised());
  }
  console.log("JSONSUMMARY: }");
}