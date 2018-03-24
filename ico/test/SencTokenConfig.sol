pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// SencTokenConfig - SENC Token Configuration 
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

contract SencTokenConfig {
    string public constant NAME = "Sentinel Chain Token";
    string public constant SYMBOL = "SENC";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 500000000 * DECIMALSFACTOR;
}