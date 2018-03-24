#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`
ZEPPELINSOURCEDIR=`grep ^ZEPPELINSOURCEDIR= settings.txt | sed "s/^.*=//"`

CROWDSALESOL=`grep ^CROWDSALESOL= settings.txt | sed "s/^.*=//"`
CROWDSALEJS=`grep ^CROWDSALEJS= settings.txt | sed "s/^.*=//"`
WHITELISTSOL=`grep ^WHITELISTSOL= settings.txt | sed "s/^.*=//"`
WHITELISTJS=`grep ^WHITELISTJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

START_DATE=`echo "$CURRENTTIME+30" | bc`
START_DATE_S=`date -r $START_DATE -u`
END_DATE=`echo "$CURRENTTIME+60*1+30" | bc`
END_DATE_S=`date -r $END_DATE -u`
REFUND_END_DATE=`echo "$CURRENTTIME+60*2" | bc`
REFUND_END_DATE_S=`date -r $REFUND_END_DATE -u`

printf "MODE               = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "ZEPPELINSOURCEDIR  = '$ZEPPELINSOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALESOL       = '$CROWDSALESOL'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALEJS        = '$CROWDSALEJS'\n" | tee -a $TEST1OUTPUT
printf "WHITELISTSOL       = '$WHITELISTSOL'\n" | tee -a $TEST1OUTPUT
printf "WHITELISTJS        = '$WHITELISTJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT        = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS       = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "START_DATE         = '$START_DATE' '$START_DATE_S'\n" | tee -a $TEST1OUTPUT
printf "END_DATE           = '$END_DATE' '$END_DATE_S'\n" | tee -a $TEST1OUTPUT
printf "REFUND_END_DATE    = '$REFUND_END_DATE' '$REFUND_END_DATE_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/*.sol .`
`cp -rp $ZEPPELINSOURCEDIR/* .`

# --- Modify parameters ---
`perl -pi -e "s/zeppelin-solidity\/contracts\///" *.sol`
#`perl -pi -e "s/WhiteListedBasic whiteListed;/WhiteListedBasic public whiteListed;/" $CROWDSALESOL`
# `perl -pi -e "s/endDate \= 1513872000;.*$/endDate \= $END_DATE; \/\/ $END_DATE_S/" $CROWDSALESOL`
#`perl -pi -e "s/uint256 removed;/uint256 public removed;/" $WHITELISTSOL`
#`perl -pi -e "s/address\[\] addresses;/address\[\] public addresses;/" $WHITELISTSOL`
#`perl -pi -e "s/address primaryOperator;/address public primaryOperator;/" Operatable.sol`
#`perl -pi -e "s/address secondaryOperator;/address public secondaryOperator;/" Operatable.sol`

for FILE in *.sol
do
  DIFFS1=`diff $SOURCEDIR/$FILE $FILE`
  echo "--- Differences $SOURCEDIR/$FILE $FILE ---" | tee -a $TEST1OUTPUT
  echo "$DIFFS1" | tee -a $TEST1OUTPUT
done

solc_0.4.20 --version | tee -a $TEST1OUTPUT

echo "var crowdsaleOutput=`solc_0.4.20 --optimize --pretty-json --combined-json abi,bin,interface $CROWDSALESOL`;" > $CROWDSALEJS


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$CROWDSALEJS");
loadScript("functions.js");

var fullTest = false;

var tokenAbi = JSON.parse(crowdsaleOutput.contracts["SencToken.sol:SencToken"].abi);
var tokenBin = "0x" + crowdsaleOutput.contracts["SencToken.sol:SencToken"].bin;
var crowdsaleAbi = JSON.parse(crowdsaleOutput.contracts["SencTokenSale.sol:SencTokenSale"].abi);
var crowdsaleBin = "0x" + crowdsaleOutput.contracts["SencTokenSale.sol:SencTokenSale"].bin;
var whitelistAbi = JSON.parse(crowdsaleOutput.contracts["WhiteListed.sol:WhiteListed"].abi);
var whitelistBin = "0x" + crowdsaleOutput.contracts["WhiteListed.sol:WhiteListed"].bin;

console.log("DATA: var tokenAbi=" + JSON.stringify(tokenAbi) + ";");
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));
console.log("DATA: var crowdsaleAbi=" + JSON.stringify(crowdsaleAbi) + ";");
// console.log("DATA: crowdsaleBin=" + JSON.stringify(crowdsaleBin));
console.log("DATA: var whitelistAbi=" + JSON.stringify(whitelistAbi) + ";");
// console.log("DATA: whitelistBin=" + JSON.stringify(whitelistBin));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployWhitelistMessage = "Deploy Whitelist Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployWhitelistMessage + " ----------");
var whitelistContract = web3.eth.contract(whitelistAbi);
var whitelistTx = null;
var whitelistAddress = null;
var whitelist = whitelistContract.new({from: contractOwnerAccount, data: whitelistBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        whitelistTx = contract.transactionHash;
      } else {
        whitelistAddress = contract.address;
        addAccount(whitelistAddress, "Whitelist Contract");
        addWhitelistContractAddressAndAbi(whitelistAddress, whitelistAbi);
        console.log("DATA: var whitelistAddress=\"" + whitelistAddress + "\";");
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(whitelistTx, deployWhitelistMessage);
printTxData("whitelistAddress=" + whitelistAddress, whitelistTx);
printWhitelistContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var whitelist0_Message = "Add To Whitelist";
var tenEther = web3.toWei("10", "ether");
var addr1 = [account17, account18, account19, account20, account21];
var batches1 = [0, 1, 2, 3, 1];
var weiAllocation1 = [tenEther, tenEther, tenEther, tenEther * 2000, tenEther];
// var tenEther = web3.toWei("10", "ether");
var addr2 = [account22, account23, account24, account25, account26, account27, account28, account29, account30, account31];
var batches2 = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
var weiAllocation2 = [tenEther, tenEther, tenEther, tenEther, tenEther, tenEther, tenEther, tenEther, tenEther, tenEther];
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + whitelist0_Message + " ----------");
var whitelist0_1Tx = whitelist.addWhiteListed(addr1, batches1, weiAllocation1, {from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
var whitelist0_2Tx = whitelist.addWhiteListed(addr2, batches2, weiAllocation2, {from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(whitelist0_1Tx, whitelist0_Message);
failIfTxStatusError(whitelist0_2Tx, whitelist0_Message);
printTxData("whitelist0_1Tx", whitelist0_1Tx);
printTxData("whitelist0_2Tx", whitelist0_2Tx);
printWhitelistContractDetails();
console.log("RESULT: ");


if (fullTest) {
// -----------------------------------------------------------------------------
var whitelist1_Message = "Update Whitelist";
var twentyEther = web3.toWei("20", "ether");
var addr3 = [account21, account22];
var batches3 = [2, 3];
var weiAllocation3 = [twentyEther, twentyEther];
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + whitelist1_Message + " ----------");
var whitelist1_1Tx = whitelist.setAllocation(addr3, weiAllocation3, {from: contractOwnerAccount, gas: 3000000, gasPrice: defaultGasPrice});
var whitelist1_2Tx = whitelist.setBatchNumber(addr3, batches3, {from: contractOwnerAccount, gas: 3000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(whitelist1_1Tx, whitelist1_Message);
failIfTxStatusError(whitelist1_2Tx, whitelist1_Message);
printTxData("whitelist1_1Tx", whitelist1_1Tx);
printTxData("whitelist1_2Tx", whitelist1_2Tx);
printWhitelistContractDetails();
console.log("RESULT: ");
}


if (fullTest) {
// -----------------------------------------------------------------------------
var removeFromWhitelist_Message = "Remove From Whitelist";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + removeFromWhitelist_Message + " ----------");
console.log("RESULT: BEFORE - whitelist.batchMap(account30)=" + JSON.stringify(whitelist.batchMap(account30)));
var removeFromWhitelist_1Tx = whitelist.removeWhiteListed(account30, {from: contractOwnerAccount, gas: 3000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
console.log("RESULT: AFTER - whitelist.batchMap(account30)=" + JSON.stringify(whitelist.batchMap(account30)));
printBalances();
failIfTxStatusError(removeFromWhitelist_1Tx, removeFromWhitelist_Message);
printTxData("removeFromWhitelist_1Tx", removeFromWhitelist_1Tx);
printWhitelistContractDetails();
console.log("RESULT: ");
}


// -----------------------------------------------------------------------------
var crowdsaleMessage = "Deploy Crowdsale Contract";
var batchStartTime0 = new Date()/1000;
var batchStartTime1 = parseInt(batchStartTime0) + 30;
var batchStartTime2 = parseInt(batchStartTime0) + 60;
var batchStartTime3 = parseInt(batchStartTime0) + 90;
var endTime = parseInt(batchStartTime0) + 120;
var usdPerMEth = ethPriceUSD * 1000000;
var batchStartTimes = [batchStartTime0, batchStartTime1, batchStartTime2, batchStartTime3];
var presaleWei = web3.toWei("7575.66790165836", "ether");
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + crowdsaleMessage + " ----------");
console.log("RESULT: presaleWei=" + presaleWei);
var crowdsaleContract = web3.eth.contract(crowdsaleAbi);
var crowdsaleTx = null;
var crowdsaleAddress = null;
var tokenAddress = null;
var token = null;
var crowdsale = crowdsaleContract.new(batchStartTimes, endTime, usdPerMEth, presaleWei, whitelistAddress, walletAgTech, walletFoundingTeam,
  walletEarlySupporters, walletTreasury, walletPresaleGroup, contractOwnerAccount, {from: contractOwnerAccount, data: crowdsaleBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        crowdsaleTx = contract.transactionHash;
      } else {
        crowdsaleAddress = contract.address;
        addAccount(crowdsaleAddress, "Crowdsale Contract");
        addCrowdsaleContractAddressAndAbi(crowdsaleAddress, crowdsaleAbi);
        console.log("DATA: var crowdsaleAddress=\"" + crowdsaleAddress + "\";");
        tokenAddress = crowdsale.token();
        console.log("DATA: var tokenAddress=\"" + tokenAddress + "\";");
        token = eth.contract(tokenAbi).at(tokenAddress);
        addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(crowdsaleTx, crowdsaleMessage);
printTxData("crowdsaleAddress=" + crowdsaleAddress, crowdsaleTx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("batchStartTime0", batchStartTime0, 0);


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution #1 - During Batch 0 Period";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1_1Tx = eth.sendTransaction({from: account17, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution1_2Tx = eth.sendTransaction({from: account18, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution1_1Tx, sendContribution1Message + " - ac17 1 ETH");
passIfTxStatusError(sendContribution1_2Tx, sendContribution1Message + " - ac18 1 ETH - Expecting failure - wrong batch");
printTxData("sendContribution1_1Tx", sendContribution1_1Tx);
printTxData("sendContribution1_2Tx", sendContribution1_2Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("batchStartTime1", batchStartTime1, 0);


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution #2 - During Batch 1 Period";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2_1Tx = eth.sendTransaction({from: account17, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution2_2Tx = eth.sendTransaction({from: account18, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution2_3Tx = eth.sendTransaction({from: account19, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution2_1Tx, sendContribution2Message + " - ac17 1 ETH");
failIfTxStatusError(sendContribution2_2Tx, sendContribution2Message + " - ac18 1 ETH");
passIfTxStatusError(sendContribution2_3Tx, sendContribution2Message + " - ac19 1 ETH - Expecting failure - wrong batch");
printTxData("sendContribution2_1Tx", sendContribution2_1Tx);
printTxData("sendContribution2_2Tx", sendContribution2_2Tx);
printTxData("sendContribution2_3Tx", sendContribution2_3Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("batchStartTime2", batchStartTime2, 0);


// -----------------------------------------------------------------------------
var sendContribution3Message = "Send Contribution #3 - During Batch 2 Period";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution3Message);
var sendContribution3_1Tx = eth.sendTransaction({from: account17, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution3_2Tx = eth.sendTransaction({from: account18, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution3_3Tx = eth.sendTransaction({from: account19, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution3_4Tx = eth.sendTransaction({from: account20, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution3_1Tx, sendContribution3Message + " - ac17 1 ETH");
failIfTxStatusError(sendContribution3_2Tx, sendContribution3Message + " - ac18 1 ETH");
failIfTxStatusError(sendContribution3_3Tx, sendContribution3Message + " - ac19 1 ETH");
passIfTxStatusError(sendContribution3_4Tx, sendContribution3Message + " - ac20 1 ETH - Expecting failure - wrong batch");
printTxData("sendContribution3_1Tx", sendContribution3_1Tx);
printTxData("sendContribution3_2Tx", sendContribution3_2Tx);
printTxData("sendContribution3_3Tx", sendContribution3_3Tx);
printTxData("sendContribution3_4Tx", sendContribution3_4Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("batchStartTime3", batchStartTime3, 0);


// -----------------------------------------------------------------------------
var sendContribution4Message = "Send Contribution #4 - During Batch 3 Period";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution4Message);
var sendContribution4_1Tx = eth.sendTransaction({from: account17, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution4_2Tx = eth.sendTransaction({from: account18, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution4_3Tx = eth.sendTransaction({from: account19, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution4_4Tx = eth.sendTransaction({from: account20, to: crowdsaleAddress, gas: 400000, value: web3.toWei("9459.5848770", "ether")});
var sendContribution4_5Tx = eth.sendTransaction({from: account21, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution4_1Tx, sendContribution4Message + " - ac17 1 ETH");
failIfTxStatusError(sendContribution4_2Tx, sendContribution4Message + " - ac18 1 ETH");
failIfTxStatusError(sendContribution4_3Tx, sendContribution4Message + " - ac19 1 ETH");
failIfTxStatusError(sendContribution4_4Tx, sendContribution4Message + " - ac20 9,459.5848770 ETH");
failIfTxStatusError(sendContribution4_5Tx, sendContribution4Message + " - ac21 1 ETH - Expecting failure - wrong batch");
printTxData("sendContribution4_1Tx", sendContribution4_1Tx);
printTxData("sendContribution4_2Tx", sendContribution4_2Tx);
printTxData("sendContribution4_3Tx", sendContribution4_3Tx);
printTxData("sendContribution4_4Tx", sendContribution4_4Tx);
printTxData("sendContribution4_5Tx", sendContribution4_5Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("endTime", endTime, 0);


// -----------------------------------------------------------------------------
var finalise_Message = "Finalise";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finalise_Message);
var finalise_1Tx = crowdsale.finalize({from: contractOwnerAccount, gas: 300000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(finalise_1Tx, finalise_Message);
printTxData("finalise_1Tx", finalise_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


exit;


waitUntil("startTime", crowdsale.startTime(), 0);


// -----------------------------------------------------------------------------
var sendContribution0Message = "Send Contribution #0 - During restricted participation period";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution0Message);
var sendContribution0_1Tx = eth.sendTransaction({from: account5, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.5", "ether")});
var sendContribution0_2Tx = eth.sendTransaction({from: account6, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.5", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution0_1Tx, sendContribution0Message + " - ac5 0.5 ETH");
passIfTxStatusError(sendContribution0_2Tx, sendContribution0Message + " - ac6 0.5 ETH - Expecting failure - no cap");
printTxData("sendContribution0_1Tx", sendContribution0_1Tx);
printTxData("sendContribution0_2Tx", sendContribution0_2Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("startTime + RESTRICTED_PERIOD_DURATION", crowdsale.startTime(), 30);


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution #1 - After restricted participation period";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1_1Tx = eth.sendTransaction({from: account5, to: crowdsaleAddress, gas: 400000, value: web3.toWei("40000", "ether")});
while (txpool.status.pending > 0) {
}
var sendContribution1_2Tx = eth.sendTransaction({from: account6, to: crowdsaleAddress, gas: 400000, value: web3.toWei("40000", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution1_1Tx, sendContribution1Message + " - ac5 40,000 ETH");
failIfTxStatusError(sendContribution1_2Tx, sendContribution1Message + " - ac6 40,000 ETH");
printTxData("sendContribution1_1Tx", sendContribution1_1Tx);
printTxData("sendContribution1_2Tx", sendContribution1_2Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("endTime", crowdsale.endTime(), 0);


// -----------------------------------------------------------------------------
var finalise_Message = "Finalise";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finalise_Message);
var finalise_1Tx = crowdsale.finalize({from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(finalise_1Tx, finalise_Message);
printTxData("finalise_1Tx", finalise_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var claimTokens_Message = "Claim Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: " + claimTokens_Message);
var claimTokens_1Tx = crowdsale.claimTokens("1000000000000000000000", {from: account5, gas: 100000, gasPrice: defaultGasPrice});
var claimTokens_2Tx = crowdsale.claimAllTokens({from: account6, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(claimTokens_1Tx, claimTokens_Message + " - ac5 claim 1,000");
failIfTxStatusError(claimTokens_2Tx, claimTokens_Message + " - ac6 claimAll");
printTxData("claimTokens_1Tx", claimTokens_1Tx);
printTxData("claimTokens_2Tx", claimTokens_2Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var refundEthers0_Message = "Refund Ethers #1";
// -----------------------------------------------------------------------------
console.log("RESULT: " + refundEthers0_Message);
var refundEthers0_1Tx = crowdsale.refundEther("1000000000000000000000", {from: account5, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(refundEthers0_1Tx, refundEthers0_Message + " - ac5 refund 1,000 ETH");
printTxData("refundEthers0_1Tx", refundEthers0_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var refundEthers1_Message = "Refund Ethers #2";
// -----------------------------------------------------------------------------
console.log("RESULT: " + refundEthers1_Message);
var refundEthers1_1Tx = crowdsale.refundAllEther({from: account5, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(refundEthers1_1Tx, refundEthers1_Message + " - ac5 refund remaining");
printTxData("refundEthers1_1Tx", refundEthers1_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("refundEndTime", crowdsale.refundEndTime(), 0);


// -----------------------------------------------------------------------------
var finaliseRefund_Message = "Finalise Refund";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finaliseRefund_Message);
var finaliseRefund_1Tx = crowdsale.finalizeRefunds({from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(finaliseRefund_1Tx, finaliseRefund_Message);
printTxData("finaliseRefund_1Tx", finaliseRefund_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
var setup_Message = "Setup";
// -----------------------------------------------------------------------------
console.log("RESULT: " + setup_Message);
var setup_1Tx = crowdsale.setBTTSToken(tokenAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_2Tx = crowdsale.setBonusList(bonusListAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_3Tx = crowdsale.setEndDate($END_DATE, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_4Tx = token.setMinter(crowdsaleAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_5Tx = bonusList.add([account3], 1, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_6Tx = bonusList.add([account4], 2, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_7Tx = bonusList.add([account5], 3, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(setup_1Tx, setup_Message + " - crowdsale.setBTTSToken(tokenAddress)");
failIfTxStatusError(setup_2Tx, setup_Message + " - crowdsale.setBonusList(bonusListAddress)");
failIfTxStatusError(setup_3Tx, setup_Message + " - crowdsale.setEndDate($END_DATE)");
failIfTxStatusError(setup_4Tx, setup_Message + " - token.setMinter(crowdsaleAddress)");
failIfTxStatusError(setup_5Tx, setup_Message + " - bonusList.add([account3], 1)");
failIfTxStatusError(setup_6Tx, setup_Message + " - bonusList.add([account4], 2)");
failIfTxStatusError(setup_7Tx, setup_Message + " - bonusList.add([account5], 3)");
printTxData("setup_1Tx", setup_1Tx);
printTxData("setup_2Tx", setup_2Tx);
printTxData("setup_3Tx", setup_3Tx);
printTxData("setup_4Tx", setup_4Tx);
printTxData("setup_5Tx", setup_5Tx);
printTxData("setup_6Tx", setup_6Tx);
printTxData("setup_7Tx", setup_7Tx);
printCrowdsaleContractDetails();
printBonusListContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var addPrecommitment_Message = "Add Precommitment";
// -----------------------------------------------------------------------------
console.log("RESULT: " + addPrecommitment_Message);
var addPrecommitment_1Tx = crowdsale.addPrecommitment(account7, web3.toWei(1000, "ether"), 35, {from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addPrecommitment_1Tx, addPrecommitment_Message + " - ac7 1,000 ETH with 35% bonus");
printTxData("addPrecommitment_1Tx", addPrecommitment_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution0Message = "Send Contribution #0 - Before Crowdsale Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution0Message);
var sendContribution0_1Tx = eth.sendTransaction({from: contractOwnerAccount, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.01", "ether")});
var sendContribution0_2Tx = eth.sendTransaction({from: contractOwnerAccount, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.02", "ether")});
var sendContribution0_3Tx = eth.sendTransaction({from: account3, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.01", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution0_1Tx, sendContribution0Message + " - owner 0.01 ETH - Owner Test Transaction");
passIfTxStatusError(sendContribution0_2Tx, sendContribution0Message + " - owner 0.02 ETH - Expecting failure - not a test transaction");
passIfTxStatusError(sendContribution0_3Tx, sendContribution0Message + " - ac3 0.01 ETH - Expecting failure");
printTxData("sendContribution0_1Tx", sendContribution0_1Tx);
printTxData("sendContribution0_2Tx", sendContribution0_2Tx);
printTxData("sendContribution0_3Tx", sendContribution0_3Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("START_DATE", crowdsale.START_DATE(), 0);


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution #1";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1_1Tx = eth.sendTransaction({from: account3, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution1_2Tx = eth.sendTransaction({from: account4, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution1_3Tx = eth.sendTransaction({from: account5, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution1_4Tx = eth.sendTransaction({from: account6, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution1_1Tx, sendContribution1Message + " - ac3 10 ETH - Bonus Tier 1 50%");
failIfTxStatusError(sendContribution1_2Tx, sendContribution1Message + " - ac4 10 ETH - Bonus Tier 2 20%");
failIfTxStatusError(sendContribution1_3Tx, sendContribution1Message + " - ac5 10 ETH - Bonus Tier 3 15%");
failIfTxStatusError(sendContribution1_4Tx, sendContribution1Message + " - ac6 10 ETH - No Bonus");
printTxData("sendContribution1_1Tx", sendContribution1_1Tx);
printTxData("sendContribution1_2Tx", sendContribution1_2Tx);
printTxData("sendContribution1_3Tx", sendContribution1_3Tx);
printTxData("sendContribution1_4Tx", sendContribution1_4Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution #2";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2_1Tx = eth.sendTransaction({from: account3, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
var sendContribution2_2Tx = eth.sendTransaction({from: account4, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
var sendContribution2_3Tx = eth.sendTransaction({from: account5, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
var sendContribution2_4Tx = eth.sendTransaction({from: account6, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution2_1Tx, sendContribution2Message + " - ac3 90 ETH - Bonus Tier 1 50%");
failIfTxStatusError(sendContribution2_2Tx, sendContribution2Message + " - ac4 90 ETH - Bonus Tier 2 20%");
failIfTxStatusError(sendContribution2_3Tx, sendContribution2Message + " - ac5 90 ETH - Bonus Tier 3 15%");
failIfTxStatusError(sendContribution2_4Tx, sendContribution2Message + " - ac6 90 ETH - No Bonus");
printTxData("sendContribution2_1Tx", sendContribution2_1Tx);
printTxData("sendContribution2_2Tx", sendContribution2_2Tx);
printTxData("sendContribution2_3Tx", sendContribution2_3Tx);
printTxData("sendContribution2_4Tx", sendContribution2_4Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
generateSummaryJSON();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution3Message = "Send Contribution #3";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution3Message);
var sendContribution3_1Tx = eth.sendTransaction({from: account8, to: crowdsaleAddress, gas: 400000, value: web3.toWei("50000", "ether")});
while (txpool.status.pending > 0) {
}
var sendContribution3_2Tx = eth.sendTransaction({from: account9, to: crowdsaleAddress, gas: 400000, value: web3.toWei("30000", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution3_1Tx, sendContribution3Message + " - ac8 50,000 ETH");
failIfTxStatusError(sendContribution3_2Tx, sendContribution3Message + " - ac9 30,000 ETH");
printTxData("sendContribution3_1Tx", sendContribution3_1Tx);
printTxData("sendContribution3_2Tx", sendContribution3_2Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var addPrecommitmentAdjustment_Message = "Add Precommitment Adjustment";
// -----------------------------------------------------------------------------
console.log("RESULT: " + addPrecommitmentAdjustment_Message);
var addPrecommitmentAdjustment_1Tx = crowdsale.addPrecommitmentAdjustment(account7, new BigNumber("111").shift(18), {from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addPrecommitmentAdjustment_1Tx, addPrecommitmentAdjustment_Message + " - ac7 + 111 GZE");
printTxData("addPrecommitmentAdjustment_1Tx", addPrecommitmentAdjustment_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var finalise_Message = "Finalise Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finalise_Message);
var finalise_1Tx = crowdsale.finalise({from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(finalise_1Tx, finalise_Message);
printTxData("finalise_1Tx", finalise_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
