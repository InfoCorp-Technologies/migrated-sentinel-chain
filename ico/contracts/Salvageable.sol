pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Salvageable - Base contract which allows children to salvage other people's 
// token that is sent to the child contract. 
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Operatable.sol";

contract Salvageable is Operatable {
    // Salvage other tokens that are accidentally sent into this token
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public canOperate {
        if (address(oddToken) == address(0)) {
            owner.transfer(amount);
            return;
        }
        oddToken.transfer(owner, amount);
    }
}