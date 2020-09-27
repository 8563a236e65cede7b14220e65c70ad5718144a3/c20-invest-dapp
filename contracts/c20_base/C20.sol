// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.0;

import './StandardToken.sol';

contract C20 is StandardToken {



    string public name = "Crypto20";
    string public symbol = "C20";
    uint256 public decimals = 18;
    string public version = "9.0";

    uint256 public tokenCap = 86206896 * 10**18;


    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;


    address public vestingContract;
    bool private vestingSet = false;


    address payable public fundWallet;

    address public controlWallet;

    uint256 public waitTime = 5 hours;



    bool public halted = false;
    bool public tradeable = false;




    uint256 public previousUpdateTime = 0;
    Price public currentPrice;
    uint256 public minAmount = 0.04 ether;


    mapping (address => Withdrawal) public withdrawals;

    mapping (uint256 => Price) public prices;

    mapping (address => bool) public whitelist;



    struct Price {
        uint256 numerator;
        uint256 denominator;
    }

    struct Withdrawal {
        uint256 tokens;
        uint256 time;
    }



    event Buy(address indexed participant, address indexed beneficiary, uint256 ethValue, uint256 amountTokens);
    event AllocatePresale(address indexed participant, uint256 amountTokens);
    event Whitelist(address indexed participant);
    event PriceUpdate(uint256 numerator, uint256 denominator);
    event AddLiquidity(uint256 ethAmount);
    event RemoveLiquidity(uint256 ethAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);



    modifier isTradeable() {
        require(tradeable || msg.sender == fundWallet || msg.sender == vestingContract);
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender]);
        _;
    }

    modifier onlyFundWallet() {
        require(msg.sender == fundWallet);
        _;
    }

    modifier onlyManagingWallets() {
        require(msg.sender == controlWallet || msg.sender == fundWallet);
        _;
    }

    modifier only_if_controlWallet() {
        if (msg.sender == controlWallet) _;
    }
    modifier require_waited() {
        require(safeSub(block.timestamp, waitTime) >= previousUpdateTime);
        _;
    }
    modifier only_if_increase (uint256 newNumerator) {
        if (newNumerator > currentPrice.numerator) _;
    }



    constructor(address controlWalletInput, uint256 priceNumeratorInput, uint256 startBlockInput, uint256 endBlockInput) {
        require(controlWalletInput != address(0));
        require(priceNumeratorInput > 0);
        require(endBlockInput > startBlockInput);
        fundWallet = msg.sender;
        controlWallet = controlWalletInput;
        whitelist[fundWallet] = true;
        whitelist[controlWallet] = true;
        currentPrice = Price(priceNumeratorInput, 1000);
        fundingStartBlock = startBlockInput;
        fundingEndBlock = endBlockInput;
        previousUpdateTime = block.timestamp;
    }



    function setVestingContract(address vestingContractInput) external onlyFundWallet {
        require(vestingContractInput != address(0));
        vestingContract = vestingContractInput;
        whitelist[vestingContract] = true;
        vestingSet = true;
    }


    function updatePrice(uint256 newNumerator) external onlyManagingWallets {
        require(newNumerator > 0);
        require_limited_change(newNumerator);

        currentPrice.numerator = newNumerator;

        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = block.timestamp;
        emit PriceUpdate(newNumerator, currentPrice.denominator);
    }

    function require_limited_change (uint256 newNumerator)
        view
        private
        only_if_controlWallet
        require_waited
        only_if_increase(newNumerator)
    {
        uint256 percentage_diff = 0;
        percentage_diff = safeMul(newNumerator, 100) / currentPrice.numerator;
        percentage_diff = safeSub(percentage_diff, 100);

        require(percentage_diff <= 20);
    }

    function updatePriceDenominator(uint256 newDenominator) external onlyFundWallet {
        require(block.number > fundingEndBlock);
        require(newDenominator > 0);
        currentPrice.denominator = newDenominator;

        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = block.timestamp;
        emit PriceUpdate(currentPrice.numerator, newDenominator);
    }

    function allocateTokens(address participant, uint256 amountTokens) private {
        require(vestingSet);

        uint256 developmentAllocation = safeMul(amountTokens, 14942528735632185) / 100000000000000000;

        uint256 newTokens = safeAdd(amountTokens, developmentAllocation);
        require(safeAdd(totalSupply, newTokens) <= tokenCap);

        totalSupply = safeAdd(totalSupply, newTokens);
        balances[participant] = safeAdd(balances[participant], amountTokens);
        balances[vestingContract] = safeAdd(balances[vestingContract], developmentAllocation);
    }

    function allocatePresaleTokens(address participant, uint amountTokens) external onlyFundWallet {
        require(block.number < fundingEndBlock);
        require(participant != address(0));
        whitelist[participant] = true;
        allocateTokens(participant, amountTokens);
        emit Whitelist(participant);
        emit AllocatePresale(participant, amountTokens);
    }

    function verifyParticipant(address participant) external onlyManagingWallets {
        whitelist[participant] = true;
        emit Whitelist(participant);
    }

    function buy() external payable {
        buyTo(msg.sender);
    }

    function buyTo(address participant) public payable onlyWhitelist {
        require(!halted);
        require(participant != address(0));
        require(msg.value >= minAmount);
        require(block.number >= fundingStartBlock && block.number < fundingEndBlock);
        uint256 icoDenominator = icoDenominatorPrice();
        uint256 tokensToBuy = safeMul(msg.value, currentPrice.numerator) / icoDenominator;
        allocateTokens(participant, tokensToBuy);

        fundWallet.transfer(msg.value);
        emit Buy(msg.sender, participant, msg.value, tokensToBuy);
    }


    function icoDenominatorPrice() public view returns (uint256) {
        uint256 icoDuration = safeSub(block.number, fundingStartBlock);
        uint256 denominator;
        if (icoDuration < 2880) {
            return currentPrice.denominator;
        } else if (icoDuration < 80640 ) {
            denominator = safeMul(currentPrice.denominator, 105) / 100;
            return denominator;
        } else {
            denominator = safeMul(currentPrice.denominator, 110) / 100;
            return denominator;
        }
    }

    function requestWithdrawal(uint256 amountTokensToWithdraw) external isTradeable onlyWhitelist {
        require(block.number > fundingEndBlock);
        require(amountTokensToWithdraw > 0);
        address payable participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw);
        require(withdrawals[participant].tokens == 0);
        balances[participant] = safeSub(balances[participant], amountTokensToWithdraw);
        withdrawals[participant] = Withdrawal({tokens: amountTokensToWithdraw, time: previousUpdateTime});
        emit WithdrawRequest(participant, amountTokensToWithdraw);
    }

    function withdraw() external {
        address payable participant = payable(msg.sender);
        uint256 tokens = withdrawals[participant].tokens;
        require(tokens > 0);
        uint256 requestTime = withdrawals[participant].time;

        Price memory price = prices[requestTime];
        require(price.numerator > 0);
        uint256 withdrawValue = safeMul(tokens, price.denominator) / price.numerator;

        withdrawals[participant].tokens = 0;
        if (address(this).balance >= withdrawValue)
            enact_withdrawal_greater_equal(participant, withdrawValue, tokens);
        else
            enact_withdrawal_less(participant, withdrawValue, tokens);
    }

    function enact_withdrawal_greater_equal(address participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(address(this).balance >= withdrawValue);
        balances[fundWallet] = safeAdd(balances[fundWallet], tokens);
        payable(participant).transfer(withdrawValue);
        emit Withdraw(payable(participant), tokens, withdrawValue);
    }
    function enact_withdrawal_less(address participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(address(this).balance < withdrawValue);
        balances[payable(participant)] = safeAdd(balances[payable(participant)], tokens);
        emit Withdraw(payable(participant), tokens, 0);
    }


    function checkWithdrawValue(uint256 amountTokensToWithdraw) public view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(msg.sender) >= amountTokensToWithdraw);
        uint256 withdrawValue = safeMul(amountTokensToWithdraw, currentPrice.denominator) / currentPrice.numerator;
        require(address(this).balance >= withdrawValue);
        return withdrawValue;
    }


    function addLiquidity() external onlyManagingWallets payable {
        require(msg.value > 0);
        emit AddLiquidity(msg.value);
    }


    function removeLiquidity(uint256 amount) external onlyManagingWallets {
        require(amount <= address(this).balance);
        fundWallet.transfer(amount);
        emit RemoveLiquidity(amount);
    }

    function changeFundWallet(address newFundWallet) external onlyFundWallet {
        require(newFundWallet != address(0));
        fundWallet = payable(newFundWallet);
    }

    function changeControlWallet(address newControlWallet) external onlyFundWallet {
        require(newControlWallet != address(0));
        controlWallet = newControlWallet;
    }

    function changeWaitTime(uint256 newWaitTime) external onlyFundWallet {
        waitTime = newWaitTime;
    }

    function updateFundingStartBlock(uint256 newFundingStartBlock) external onlyFundWallet {
        require(block.number < fundingStartBlock);
        require(block.number < newFundingStartBlock);
        fundingStartBlock = newFundingStartBlock;
    }

    function updateFundingEndBlock(uint256 newFundingEndBlock) external onlyFundWallet {
        require(block.number < fundingEndBlock);
        require(block.number < newFundingEndBlock);
        fundingEndBlock = newFundingEndBlock;
    }

    function halt() external onlyFundWallet {
        halted = true;
    }
    function unhalt() external onlyFundWallet {
        halted = false;
    }

    function enableTrading() external onlyFundWallet {
        require(block.number > fundingEndBlock);
        tradeable = true;
    }


    receive() external payable {
        require(tx.origin == msg.sender);
        buyTo(msg.sender);
    }

    fallback() external payable {}

    function claimTokens(address _token) external onlyFundWallet {
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(fundWallet, balance);
     }


    function transfer(address _to, uint256 _value) public override isTradeable returns (bool success) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public override isTradeable returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

}
