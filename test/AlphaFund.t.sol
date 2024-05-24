// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AlphaFund} from "../src/AlphaFund.sol";

contract CounterTest is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 19940270);
    }

    function test_OneTrader_OneInvestor() public {
        // Arrange
        address trader = makeAddr("trader");
        address investor = makeAddr("investor");
        vm.deal(investor, 200);

        AlphaFund fund = new AlphaFund(trader, 20);

        // Act
        // Assert
        vm.prank(trader, trader);
        uint256 amt = fund.checkAllocation();
        assertEq(amt, 0);

        vm.prank(investor, investor);
        fund.depositInvestment{value: 200}();
        assertEq(fund.investorDeposits(investor), 200);

        vm.prank(trader, trader);
        amt = fund.checkAllocation();
        assertEq(amt, 200);

        vm.prank(investor, investor);
        fund.withdraw();
        assertEq(investor.balance, 200);
    }

    function test_OneTrader_ThreeInvestors() public {
        // Arrange
        address trader = makeAddr("trader");
        address investor1 = makeAddr("investor1");
        vm.deal(investor1, 33);
        address investor2 = makeAddr("investor2");
        vm.deal(investor2, 33);
        address investor3 = makeAddr("investo3");
        vm.deal(investor3, 34);

        AlphaFund fund = new AlphaFund(trader, 20);

        // Act
        // Assert
        vm.prank(investor1, investor1);
        fund.depositInvestment{value: 33}();
        vm.prank(investor2, investor2);
        fund.depositInvestment{value: 33}();
        vm.prank(investor3, investor3);
        fund.depositInvestment{value: 34}();

        vm.prank(trader, trader);
        uint256 traderAllocation = fund.checkAllocation();
        assertEq(traderAllocation, 100);

        assertEq(fund.investorDeposits(investor1), 33);
        assertEq(fund.investorDeposits(investor2), 33);
        assertEq(fund.investorDeposits(investor3), 34);

        vm.prank(investor1, investor1);
        fund.withdraw();
        assertEq(investor1.balance, 33);

        vm.prank(investor2, investor2);
        fund.withdraw();
        assertEq(investor2.balance, 32);

        vm.prank(investor3, investor3);
        fund.withdraw();
        assertEq(investor3.balance, 35);
    }

    function test_OneTrader_ThreeInvestors_Profit() public {
        // Arrange
        address trader = makeAddr("trader");
        address investor1 = makeAddr("investor1");
        vm.deal(investor1, 33);
        address investor2 = makeAddr("investor2");
        vm.deal(investor2, 33);
        address investor3 = makeAddr("investo3");
        vm.deal(investor3, 34);

        AlphaFund fund = new AlphaFund(trader, 20);

        // Act
        // Assert
        vm.prank(investor1, investor1);
        fund.depositInvestment{value: 33}();
        vm.prank(investor2, investor2);
        fund.depositInvestment{value: 33}();
        vm.prank(investor3, investor3);
        fund.depositInvestment{value: 34}();

        vm.prank(trader, trader);
        uint256 traderAllocation = fund.checkAllocation();
        assertEq(traderAllocation, 100);

        // simulate profits
        vm.deal(address(fund), 150);

        assertEq(fund.investorDeposits(investor1), 33);
        assertEq(fund.investorDeposits(investor2), 33);
        assertEq(fund.investorDeposits(investor3), 34);

        vm.prank(investor1, investor1);
        fund.withdraw();
        assertEq(investor1.balance, 49);

        vm.prank(investor2, investor2);
        fund.withdraw();
        assertEq(investor2.balance, 49);

        vm.prank(investor3, investor3);
        fund.withdraw();
        assertEq(investor3.balance, 52);
    }

    function test_ThreeTraders_Profit() public {
        // Arrange
        address manager = makeAddr("manager");
        address trader1 = makeAddr("trader1");
        address trader2 = makeAddr("trader2");
        address investor = makeAddr("investor");
        vm.deal(investor, 100);

        AlphaFund fund = new AlphaFund(manager, 50);

        // Act
        // Assert
        vm.prank(investor, investor);
        fund.depositInvestment{value: 100}();

        vm.prank(manager, manager);
        uint256 traderAllocation = fund.checkAllocation();
        assertEq(traderAllocation, 100);

        vm.prank(manager, manager);
        fund.allocateToSubordinate(trader1, 10);
        vm.prank(manager, manager);
        fund.allocateToSubordinate(trader2, 23);

        vm.prank(manager, manager);
        traderAllocation = fund.checkAllocation();
        assertEq(traderAllocation, 67);

        vm.prank(trader1, trader1);
        traderAllocation = fund.checkAllocation();
        assertEq(traderAllocation, 10);

        vm.prank(trader2, trader2);
        traderAllocation = fund.checkAllocation();
        assertEq(traderAllocation, 23);

        vm.prank(manager, manager);
        fund.startTrading();
        // simulate profits
        vm.deal(address(fund), 200);

        vm.prank(manager, manager);
        fund.closeFund();

        assertEq(manager.balance, 33);
        assertEq(trader1.balance, 5);
        assertEq(trader2.balance, 11);
        assertEq(investor.balance, 151);
    }
}
