// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

// ============================================
//         P O G E C O I N   T O K E N
// ============================================
//    
//    Supply:     1,000,000,000 POGE
//    Decimals:   18
//    Symbol:     POGE
//    
//    Reward token for Dunk Poge NFT staking
//    Much Poge • Very Token • Wow
//    
// ============================================

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Pogecoin is ERC20 {
    constructor() ERC20("Pogecoin", "POGE") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}