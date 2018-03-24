pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// SencTokenSale - SENC Token Sale Contract
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

import "./math/SafeMath.sol";
import "./ownership/Ownable.sol";
import "./lifecycle/Pausable.sol";
import "./SencTokenSaleConfig.sol";
import "./WhiteListedBasic.sol";
import "./WhiteListed.sol";
import "./Salvageable.sol";
import "./SencToken.sol";

// ----------------------------------------------------------------------------
// The SENC Token Sale is organised as follows:
// 1. 10% (50,000,000) of total supply will be minted and sent to founding team weallet.
// 2. 20% (100,000,000) of total supply will be minted and sent to early supporter wallet.
// 3. 20% (100,000,000) of total supply will be minted and sent to presale wallet.
// 4. 20% (100,000,000) of total supply will be available for minting and purchase by public.
// 5. 30% (150,000,000) of total supply will be minted and sent to treaury wallet.
// 6. Public sale is designed to be made available in batches.
// 
// Tokens can only be purchased by contributors depending on the batch that
// contributors are assigned to in the WhiteListed smart contract to prevent a
// gas war. Each batch will be assigned a timestamp. Contributors can only 
// make purchase once the current timestamp on the main net is above the 
// batch's assigned timestamp.
//    - batch 0: start_date 00:01   (guaranteed allocations)
//    - batch 1: start_date+1 00:01 (guaranteed allocations)
//    - batch 2: start_date+2 00:01 (guaranteed and non-guaranteed allocations)
//    - batch 3: start_date+2 12:01 (guaranteed and non-guaranteed allocations)
// ----------------------------------------------------------------------------

contract SencTokenSale is SencTokenSaleConfig, Ownable, Pausable, Salvageable {
    using SafeMath for uint;
    bool public isFinalized = false;

    SencToken public token;
    uint[] public batchStartTimes;
    uint public endTime;
    uint public startTime;
    address public agTechWallet;        // InfoCorp AgTech Wallet Address to receive ETH
    uint public usdPerMEth;             // USD per million ETH. E.g. ETHUSD 844.81 is specified as 844,810,000
    uint public publicSaleSencPerMEth;  // Amount of token 1 million ETH can buy in public sale
    uint public privateSaleSencPerMEth; // Amount of token 1 million ETH can buy in private sale
    uint public weiRaised;              // Amount of raised money in WEI
    WhiteListedBasic public whiteListed;
    uint public numContributors;        // Discrete number of contributors

    mapping (address => uint) public contributions; // to allow them to have multiple spends

    event Finalized();
    event TokenPurchase(address indexed beneficiary, uint value, uint amount);
    event TokenPresale(address indexed purchaser, uint amount);
    event TokenFoundingTeam(address purchaser, uint amount);
    event TokenTreasury(address purchaser, uint amount);
    event EarlySupporters(address purchaser, uint amount);

    function SencTokenSale(uint[] _batchStartTimes, uint _endTime, uint _usdPerMEth, uint _presaleWei,
        WhiteListedBasic _whiteListed, address _agTechWallet,  address _foundingTeamWallet,
        address _earlySupportersWallet, address _treasuryWallet, address _presaleWallet, address _tokenIssuer
    ) public {
        require(_batchStartTimes.length > 0);
        // require (now < batchStartTimes[0]);
        for (uint i = 0; i < _batchStartTimes.length - 1; i++) {
            require(_batchStartTimes[i+1] > _batchStartTimes[i]);
        }
        require(_endTime >= _batchStartTimes[_batchStartTimes.length - 1]);
        require(_usdPerMEth > 0);
        require(_whiteListed != address(0));
        require(_agTechWallet != address(0));
        require(_foundingTeamWallet != address(0));
        require(_earlySupportersWallet != address(0));
        require(_presaleWallet != address(0));
        require(_treasuryWallet != address(0));
        owner = _tokenIssuer;

        batchStartTimes = _batchStartTimes;
        startTime = _batchStartTimes[0];
        endTime = _endTime;
        agTechWallet = _agTechWallet;
        whiteListed = _whiteListed;
        weiRaised = _presaleWei;
        usdPerMEth = _usdPerMEth;
        publicSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PUBLICSALE_USD_PER_MSENC);
        privateSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PRIVATESALE_USD_PER_MSENC);

        // Let the token stuff begin
        token = new SencToken();

        // Mint initial tokens
        mintEarlySupportersTokens(_earlySupportersWallet, TOKEN_EARLYSUPPORTERS);
        mintPresaleTokens(_presaleWallet, TOKEN_PRESALE);
        mintTreasuryTokens(_treasuryWallet, TOKEN_TREASURY);
        mintFoundingTeamTokens(_foundingTeamWallet, TOKEN_FOUNDINGTEAM);
    }

    function getBatchStartTimesLength() public view returns (uint) {
        return batchStartTimes.length;
    }

    function updateBatchStartTime(uint _batchNumber, uint _batchStartTime) public canOperate {
        batchStartTimes[_batchNumber] = _batchStartTime;
        for (uint i = 0; i < batchStartTimes.length - 1; i++) {
            require(batchStartTimes[i+1] > batchStartTimes[i]);
        }
    }

    function updateEndTime(uint _endTime) public canOperate {
        require(_endTime >= batchStartTimes[batchStartTimes.length - 1]);
        endTime = _endTime;
    }

    function updateUsdPerMEth(uint _usdPerMEth) public canOperate {
        require(now < batchStartTimes[0]);
        usdPerMEth = _usdPerMEth;
        publicSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PUBLICSALE_USD_PER_MSENC);
        privateSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PRIVATESALE_USD_PER_MSENC);
    }

    function mintEarlySupportersTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        EarlySupporters(addr, amount);
    }

    function mintTreasuryTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        TokenTreasury(addr, amount);
    }

    function mintFoundingTeamTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        TokenFoundingTeam(addr, amount);
    }

    function mintPresaleTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        TokenPresale(addr, amount);
    }

    // Only fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address beneficiary, uint weiAmount) internal whenNotPaused {
        require(beneficiary != address(0));
        require(isWhiteListed(beneficiary));
        require(isWithinPeriod(beneficiary));
        require(isWithinAllocation(beneficiary, weiAmount));

        uint tokens = weiAmount.mul(publicSaleSencPerMEth).div(MILLION);
        weiRaised = weiRaised.add(weiAmount);

        if (contributions[beneficiary] == 0) {
            numContributors++;
        }

        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);
        token.mint(beneficiary, tokens);
        TokenPurchase(beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function ethRaised() public view returns(uint) {
        return weiRaised.div(10 ** 18);
    }

    function usdRaised() public view returns(uint) {
        return weiRaised.mul(usdPerMEth).div(MILLION);
    }

    function sencSold() public view returns(uint) {
        return token.totalSupply();
    }

    function sencBalance() public view returns(uint) {
        return token.TOTALSUPPLY().sub(token.totalSupply());
    }

    // This can be used after the sale is over and tokens are unpaused
    function reclaimTokens() external canOperate {
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

    // Batch is in 0..n-1 format
    function isBatchActive(uint batch) public view returns (bool) {
        if (now > endTime) {
            return false;
        }
        if (uint(batch) >= batchStartTimes.length) {
            return false;
        }
        if (now > batchStartTimes[batch]) {
            return true;
        }
        return false;
    }

    // Returns
    // 0                           - not started
    // 1..batchStartTimes.length   - batch plus 1
    // batchStartTimes.length + 1  - ended
    function batchActive() public view returns (uint) {
        if (now > endTime) {
            return batchStartTimes.length + 1;
        }
        for (uint i = batchStartTimes.length; i > 0; i--) {
            if (now > batchStartTimes[i-1]) {
                return i;
            }
        }
        return 0;
    }

    // Return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // Send ether to the fund collection wallet
    function forwardFunds() internal {
        agTechWallet.transfer(msg.value);
    }

    // Buyer must be whitelisted
    function isWhiteListed(address beneficiary) internal view returns (bool) {
        return whiteListed.isWhiteListed(beneficiary);
    }

    // Buyer must by within assigned batch period
    function isWithinPeriod(address beneficiary) internal view returns (bool) {
        uint batchNumber = whiteListed.getBatchNumber(beneficiary);
        return now >= batchStartTimes[batchNumber] && now <= endTime;
    }

    // Buyer must by withint allocated amount
    function isWithinAllocation(address beneficiary, uint weiAmount) internal view returns (bool) {
        uint allocation = whiteListed.getAllocated(beneficiary);
        return (weiAmount >= MIN_CONTRIBUTION) && (weiAmount.add(contributions[beneficiary]) <= allocation);
    }

    // Must be called after crowdsale ends, to do some extra finalization
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    // Stops the minting and transfer token ownership to sale owner. Mints unsold tokens to owner
    function finalization() internal {
        token.mint(owner,sencBalance());
        token.finishMinting();
        token.transferOwnership(owner);
    }
}