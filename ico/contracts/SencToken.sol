pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// SencToken - ERC20 Token
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

import "./zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./SencTokenConfig.sol";
import "./Salvageable.sol";

// ----------------------------------------------------------------------------
// The SENC token is an ERC20 token that:
// 1. Token is paused by default and is only allowed to be unpaused once the
//    Vesting contract is activated.
// 2. Tokens are created on demand up to TOTALSUPPLY or until minting is
//    disabled.
// 3. Token can airdropped to a group of recipients as long as the contract
//    has sufficient balance.
// ----------------------------------------------------------------------------

contract SencToken is PausableToken, SencTokenConfig, Salvageable {
    using SafeMath for uint;

    string public name = NAME;
    string public symbol = SYMBOL;
    uint8 public decimals = DECIMALS;
    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function SencToken() public {
        paused = true;
    }

    function pause() onlyOwner public {
        revert();
    }

    function unpause() onlyOwner public {
        super.unpause();
    }

    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    // Airdrop tokens from bounty wallet to contributors as long as there are enough balance
    function airdrop(address bountyWallet, address[] dests, uint[] values) public onlyOwner returns (uint) {
        require(dests.length == values.length);
        uint i = 0;
        while (i < dests.length && balances[bountyWallet] >= values[i]) {
            this.transferFrom(bountyWallet, dests[i], values[i]);
            i += 1;
        }
        return(i);
    }
}