// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./c20_base/C20.sol";
import "./access/Ownable.sol";
import "./math/SafeMathNew.sol";
import "./utils/Suspendable.sol";


/// @title C20InvestBase Smart Contract
/// @author Invictus Capital
/// @notice Base Contract for C20 resale
/// @dev A smart contract that acts as an exchange for the
/// purchase of C20 tokens. The requirements are that we
/// use forward pricing and that the contract is upgradeable.
/// This contract represents the implementation logic for the
/// token purchase and will be where transactions are forwarded to
/// from the proxy contract.
///
/// The contract is Ownable to restrict access to the administrative
/// functions such as setC20Address and suspending the contract. The
/// contract is also Suspendable and favours suspension over selfdestruct()
/// as in the former case a transaction sent to the contract address
/// (say after upgrade) will revert, whereas in the latter case, ether
/// sent to this address will be lost.
///
/// This contract is the base contract that C20Invest and C20InvestInitializable
/// inherit from, the only difference between the two being that the former has
/// a constructor and the latter has an initializer.
/// The underlying logic is kept in this contract so the difference between
/// the inheriting contracts is solely the usage of constructor versus initializer.
contract C20InvestBase {
    using SafeMathNew for uint256;

    /// @dev State variable for C20 instance
    C20 c20Instance;

    /// @dev Address of the external caller of _priceUpdate for access
    /// control purposes
    address private oracleAddress;

    /// @dev The previousUpdateTime in the C20 contract after a price
    /// update has taken place
    uint256 public currentTime;

    /// @dev A mapping to allow us to access the forward time and thus
    /// the forward price of the transaction, given the time the buy
    /// request was made
    mapping (uint256 => uint256) forwardTimes;

    /// @dev The minimum investment a user is allowed to send
    uint256 MIN_INVESTMENT = 0.1 ether;

    /// @dev Temporary storage for user's ether balance before
    /// conversion takes place
    mapping (address => uint256) public userBalances;

    /// @dev Temporary storage for the time the user sent ether
    /// to this contract. This allows the forward pricing mechanism
    /// to work as this time will be compared with C20.previousUpdateTime
    /// to decide when the tokens can be redeemed
    mapping (address => uint256) public requestTime;

    /// @dev Allows changing the address of the C20 contract in the
    /// event of an upgrade. The inheriting contract should wrap this
    /// function with onlyOwner to protect from it being called by
    /// anyone.
    /// @param c20Address The address of the currently active
    /// C20 smart contract
    function _setC20Address(address c20Address) internal {
        c20Instance = C20(payable(c20Address));
    }

    /// @dev The main function called by receive(). Records the
    /// user's balance and the current C20 previousUpdateTime
    /// required for token conversion and forward pricing
    /// mechanisms
    function buy() public payable {
        require(
            msg.value >= MIN_INVESTMENT,
            "C20Invest: ether received below minimum investment"
        );
        requestTime[msg.sender] = c20Instance.previousUpdateTime();
        userBalances[msg.sender] += msg.value;
    }

    /// @dev Allows the user to redeem their tokens given the amount
    /// of ether the user had previously sent to this contract and
    /// the previous C20 price update.
    ///
    /// We first check if the C20 price has been updated since the time
    /// the user last sent ether to the contract. We then see if the user
    /// has a positive ether balance for conversion. We check that the
    /// current C20 token balance of this contract is greater than zero and
    /// then proceed with calculating the number of tokens.
    ///
    /// The logic for the conversion of tokens is almost identical to the
    /// buyTo() function in the C20 smart contract. We multiply the user's
    /// ether balance by the C20's currentPrice numerator and divide by its
    /// denominator (versus the C20 version that uses icoDenominator).
    ///
    /// A refund is also possible if the user had deposited more ether than
    /// tokens available in the smart contract. In this case, the remaining
    /// ether balance is transferred back to the user and the remainder of
    /// tokens within this contract transferred to their account. The contract
    /// should then enter a suspended state until refilled with tokens and
    /// manually unsuspended.
    function getTokens() external {

        uint256 contractTokenBalance = c20Instance.balanceOf(address(this));
        uint256 numTokens = 0;
        uint256 priceNumerator;
        uint256 priceDenominator;
        uint256 refund = 0;

        // Forward pricing mechanism
        require(
            requestTime[msg.sender] < c20Instance.previousUpdateTime(),
            "C20Invest: price has not updated yet"
        );

        // Check for positive user balance
        require(
            userBalances[msg.sender] > 0,
            "C20Invest: user has no ether for conversion"
        );

        // Check for positive contract balance
        require(
             contractTokenBalance > 0,
            "C20Invest: no tokens left in this account"
        );

        // Get the current price from the C20 instance and work out the
        // number of tokens the user can purchase given their current
        // balance
        (priceNumerator, priceDenominator) = c20Instance.currentPrice();
        numTokens = priceNumerator.mul(userBalances[msg.sender]).div(priceDenominator);

        // Check if any refund is needed
        // numTokens = ether_value * priceNumerator / priceDenominator
        // thus ether_value = numTokens * priceDenominator / priceNumerator
        // Subtract the result from the user's balance, given numTokens as the
        // number of tokens available in this contract to get the ether amount
        // we would need to refund
        if (numTokens > contractTokenBalance) {
            refund = userBalances[msg.sender].sub(contractTokenBalance.mul(priceDenominator).div(priceNumerator));
            numTokens = contractTokenBalance;
        }

        // Zero balance to prevent reentrancy attacks
        userBalances[msg.sender] = 0;

        // Perform token transfer
        c20Instance.transfer(msg.sender, numTokens);

        // Perform a refund if there is one
        if (refund != 0) {
            msg.sender.transfer(refund);
        }
    }

    /// @dev Sets the oracle address. Should be wrapped in onlyOwner or
    /// similar by the inheriting contract to restrict access.
    function _setOracleAddress(address _oracleAddress) internal {
        oracleAddress = _oracleAddress;
    }

    /// @dev Returns the current address for the oracle which calls
    /// _priceUpdate
    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    /// @dev Modifier to restrict access so that only the registered
    /// oracle address can call the marked function
    modifier onlyOracle() {
        require(msg.sender == oracleAddress);
        _;
    }

    /// @dev Updates the forwardTimes mapping when a PriceUpdate event
    /// is emitted from the C20 contract. The forward pricing mechanism
    /// depends on this information.
    function priceUpdate() public onlyOracle {
        uint256 updateTime = c20Instance.previousUpdateTime();
        forwardTimes[currentTime] = updateTime;
        currentTime = updateTime;
    }

    function getForwardPrice() public view returns(uint256 numerator, uint256 denominator) {
        return c20Instance.prices(forwardTimes[requestTime[msg.sender]]);
    }

    function getForwardTime(uint256 time) public view returns(uint256 forwardTime) {
        return forwardTimes[time];
    }

    /// @dev The receive function is triggered when ether is sent to the
    /// contract. It is just a simple wrapper for buy()
    receive() external payable {
        buy();
    }

}
