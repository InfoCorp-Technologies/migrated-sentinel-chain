pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// SencTokenSaleConfig - SENC Token Sale Configuration
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

import "./SencTokenConfig.sol";

contract SencTokenSaleConfig is SencTokenConfig {
    uint public constant TOKEN_FOUNDINGTEAM =  50000000 * DECIMALSFACTOR;
    uint public constant TOKEN_EARLYSUPPORTERS = 100000000 * DECIMALSFACTOR;
    uint public constant TOKEN_PRESALE = 100000000 * DECIMALSFACTOR;
    uint public constant TOKEN_TREASURY = 150000000 * DECIMALSFACTOR;
    uint public constant MILLION = 1000000;
    uint public constant PUBLICSALE_USD_PER_MSENC =  80000;
    uint public constant PRIVATESALE_USD_PER_MSENC =  64000;
    uint public constant MIN_CONTRIBUTION      = 120 finney;
}