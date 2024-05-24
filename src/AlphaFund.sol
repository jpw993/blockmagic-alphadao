// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

enum FundState {
    OPEN_TO_INVESTORS,
    TRADING,
    CLOSED
}

contract FundFactory {
    event FundCreated(address newAddress);

    function createAsManager(uint8 performanceFeePercent) external returns (AlphaFund) {
        return create(msg.sender, performanceFeePercent);
    }

    function create(address manager, uint8 performanceFeePercent) public returns (AlphaFund) {
        AlphaFund newFund = new AlphaFund(manager, performanceFeePercent);
        emit FundCreated(address(newFund));
        return newFund;
    }
}

contract AlphaFund {
    FundState public state;
    address payable public immutable manager;
    address payable[] public traders;
    mapping(address => uint256) public tradingAllocations;
    address payable[] public investors;
    mapping(address => uint256) public investorDeposits;
    uint256 public totalDeposited = 0;
    uint8 public performanceFeePercent;

    constructor(address _manager, uint8 _performanceFeePercent) {
        require(_performanceFeePercent < 100, "Performance fee percentage must be less than 100%");
        state = FundState.OPEN_TO_INVESTORS;
        manager = payable(_manager);
        traders.push(manager);
        performanceFeePercent = _performanceFeePercent;
    }

    /**
     * @dev Modifier that checks if the sender is the manager of this fund.
     * Functions using this modifier can only be called by the fund's manager.
     */
    modifier onlyManager() {
        require(msg.sender == manager, "You are not the manager!");
        _;
    }

    /**
     * @dev Modifier that checks if the sender's trading allocation is within the allowed limit.
     * It calculates the amount spent during the function execution and ensures it does not exceed the trading allocation.
     */
    modifier onlyWithinLimit() {
        uint256 tradingAmtAllowed = tradingAllocations[msg.sender];
        uint256 balanceBefore = address(this).balance;
        _;
        uint256 amtSpent = balanceBefore - address(this).balance;
        require(tradingAmtAllowed >= amtSpent, "Trading allocation limit breached!");
    }

    modifier onlyOpenToInvesters() {
        require(state == FundState.OPEN_TO_INVESTORS, "This fund is not currently open to investors");
        _;
    }

    modifier onlyTrading() {
        require(state == FundState.TRADING, "This fund is not currently trading");
        _;
    }

    function allocateToSubordinate(address subordinate, uint8 amt) external onlyManager {
        require(tradingAllocations[manager] >= amt, "Cannot allocate more than you have");
        if (tradingAllocations[subordinate] > 0) {
            revert("Subordinate already has allocation");
        }
        tradingAllocations[msg.sender] -= amt;
        tradingAllocations[subordinate] += amt;
        traders.push(payable(subordinate));
    }

    function removeSubordinate(address subordinate) external onlyManager {
        uint256 amt = tradingAllocations[subordinate];
        tradingAllocations[subordinate] = 0;
        tradingAllocations[manager] += amt;
    }

    function startTrading() external onlyManager {
        state = FundState.TRADING;
    }

    function closeFund() external onlyManager {
        uint256 cpi = getCpi();
        uint256 balancePastHurdle = address(this).balance - ((address(this).balance / cpi) * 1e21);

        // check if there has been any profit
        if (balancePastHurdle > totalDeposited) {
            // calculate performance fee
            uint256 profit = balancePastHurdle - totalDeposited;
            uint256 totalPerformanceFee = (profit * performanceFeePercent) / 100;

            // transfer performance fee to traders based on allocation
            for (uint256 i = 0; i < traders.length; i++) {
                address payable traderAddr = traders[i];
                uint256 allocPercent = (tradingAllocations[traderAddr] * totalDeposited) / 100;
                if (allocPercent > 0) {
                    uint256 performanceFee = (totalPerformanceFee * allocPercent) / 100;
                    traderAddr.transfer(performanceFee);
                }
            }
        }

        // transfer remaining balance to investors
        uint256 remainingBalance = address(this).balance;
        for (uint256 i = 0; i < investors.length; i++) {
            address payable investorAddr = investors[i];
            uint256 depositAmt = investorDeposits[investorAddr];
            if (depositAmt > 0) {
                uint256 percentage = (depositAmt * 100) / totalDeposited;
                uint256 fractionToPay = (remainingBalance * percentage) / 100;
                investorAddr.transfer(fractionToPay);
            }
        }

        state = FundState.CLOSED;
    }

    function checkAllocation() external view returns (uint256) {
        return tradingAllocations[msg.sender];
    }

    event Deposited(address investor, uint256 amt);

    function depositInvestment() external payable onlyOpenToInvesters {
        investorDeposits[msg.sender] += msg.value;
        totalDeposited += msg.value;
        investors.push(payable(msg.sender));
        // initialy allocated to manager, who can then distrubute amongst team
        tradingAllocations[manager] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amt = investorDeposits[msg.sender];
        require(amt > 0, "You do not have any deposits");

        // Calculate percentage using multiplication instead of division
        uint256 percentage = (amt * 100) / totalDeposited;
        // Calculate the fraction to pay
        uint256 fractionToPay = (address(this).balance * percentage) / 100;

        // Transfer the calculated fraction to the sender
        payable(msg.sender).transfer(fractionToPay);

        // Clear the sender's deposit and update total deposited amount
        investorDeposits[msg.sender] = 0;
        totalDeposited -= amt;
    }

    event Buy(string token, uint256 amtEth, uint256 amtOther);

    function buy(string memory token, uint256 amtOther) external onlyWithinLimit onlyTrading {
        uint256 balanceBefore = address(this).balance;
        // todo: buy other token via DEX
        uint256 amtSpent = balanceBefore - address(this).balance;
        tradingAllocations[msg.sender] -= amtSpent;
        emit Buy(token, amtSpent, amtOther);
    }

    event Sell(string token, uint256 amtEth, uint256 amtOther);

    function sell(string memory token, uint256 amtOther) external onlyTrading {
        uint256 balanceBefore = address(this).balance;
        // todo: sell other token via DEX
        uint256 amtRecieved = address(this).balance - balanceBefore;
        tradingAllocations[msg.sender] += amtRecieved;
        emit Sell(token, amtRecieved, amtOther);
    }

    // allow payments of native ETH to this contract
    receive() external payable {}

    /**
     * get latest CPI value from ChainLink
     * https://data.chain.link/feeds/ethereum/mainnet/consumer-price-index
     */
    function getCpi() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9a51192e065ECC6BDEafE5e194ce54702DE4f1f5);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
