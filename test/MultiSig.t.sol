// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig public multiSig;
    address[] public owners;
    uint public confirmationsRequired;
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    address public nonOwner = address(0x4);

    function setUp() public {
        owners = [owner1, owner2, owner3];
        confirmationsRequired = 2;
        vm.prank(owner1);
        multiSig = new MultiSig(owners, confirmationsRequired);
    }

    // Test Constructor
    function testConstructor() public {
        assertEq(multiSig.owners(0), owner1);
        assertEq(multiSig.owners(1), owner2);
        assertEq(multiSig.owners(2), owner3);
        assertEq(multiSig.numConfirmationsRequired(), confirmationsRequired);
    }

    function testConstructorFailsIfOwnersInvalid() public {
        vm.expectRevert("Owners Required Must Be Greater than 1");
        address[] memory invalidOwners = new address[](0);
        new MultiSig(invalidOwners, 1);
    }

    function testConstructorFailsIfConfirmationsInvalid() public {
        vm.expectRevert(
            "Num of confirmations are not in sync with the number of owners"
        );
        new MultiSig(owners, 4); // More confirmations than owners
    }

    // Test submitTransaction
    function testSubmitTransaction() public {
        vm.startPrank(owner1);
        multiSig.submitTransaction{value: 1 ether}(owner2);
        (address to, uint value, bool executed) = multiSig.transactions(0);
        assertEq(to, owner2);
        assertEq(value, 1 ether);
        assertEq(executed, false);
    }

    function testSubmitTransactionFailsIfSenderNotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert();
        multiSig.submitTransaction{value: 1 ether}(owner2);
    }

    function testSubmitTransactionFailsIfValueZero() public {
        vm.startPrank(owner1);
        vm.expectRevert("Transfer Amount Must Be Greater Than 0");
        multiSig.submitTransaction{value: 0}(owner2);
    }

    // Test confirmTransaction
    function testConfirmTransaction() public {
        vm.startPrank(owner1);
        multiSig.submitTransaction{value: 1 ether}(owner2);
        vm.stopPrank();

        vm.startPrank(owner2);
        multiSig.confirmTransaction(0);
        vm.stopPrank();
    }

    function testConfirmTransactionFailsIfSenderNotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert();
        multiSig.confirmTransaction(0);
    }

    function testConfirmTransactionFailsIfAlreadyConfirmed() public {
        vm.startPrank(owner1);
        multiSig.submitTransaction{value: 1 ether}(owner2);
        multiSig.confirmTransaction(0);
        vm.expectRevert("Transaction Is Already Confirmed By The Owner");
        multiSig.confirmTransaction(0);
    }

    // Test executeTransaction
    function testExecuteTransaction() public {
        vm.startPrank(owner1);
        multiSig.submitTransaction{value: 1 ether}(owner2);
        multiSig.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(owner2);
        multiSig.confirmTransaction(0); // Second confirmation triggers execution
        vm.stopPrank();

        (, , bool executed) = multiSig.transactions(0);
        assertEq(executed, true);
    }

    function testExecuteTransactionFailsIfAlreadyExecuted() public {
        vm.startPrank(owner1);
        multiSig.submitTransaction{value: 1 ether}(owner2);
        multiSig.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(owner2);
        multiSig.confirmTransaction(0); // Executes the transaction
        vm.expectRevert("Transaction is already executed");
        multiSig.executeTransaction(0);
    }

    function testExecuteTransactionFailsIfNotEnoughConfirmations() public {
        vm.startPrank(owner1);
        multiSig.submitTransaction{value: 1 ether}(owner2);
        vm.expectRevert("Transaction Execution Failed");
        multiSig.executeTransaction(0);
    }

    // Test edge cases
    function testTransactionConfirmedWithMinOwners() public {
        vm.startPrank(owner1);
        multiSig.submitTransaction{value: 1 ether}(owner2);
        multiSig.confirmTransaction(0);
        // assertEq(multiSig.isTransactionConfirmed(0), false);

        vm.startPrank(owner2);
        multiSig.confirmTransaction(0);
        // assertEq(multiSig.isTransactionConfirmed(0), true);
    }

    function testTransactionFailsIfInvalidId() public {
        vm.startPrank(owner1);
        vm.expectRevert("Invalid Transaction Id");
        multiSig.confirmTransaction(999); // Non-existent transaction
    }
}
