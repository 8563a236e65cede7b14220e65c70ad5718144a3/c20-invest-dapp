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
/// purchase of :sol:contract:`C20` tokens. The requirements are that we
/// use forward pricing and that the contract is upgradeable.
/// This contract represents the implementation logic for the
/// token purchase and will be where transactions are forwarded to
/// from the proxy contract.
///
/// This contract is the base contract that :sol:contract:`C20Invest`
/// and :sol:contract:`C20InvestInitializable`
/// inherit from, the only difference between the two being that the former has
/// a constructor and the latter has an initializer.
/// The underlying logic is kept in this contract so the difference between
/// the inheriting contracts is solely the usage of constructor versus initializer.
contract C20InvestBase {
    using SafeMathNew for uint256;

    /// @dev State variable for C20 instance
    C20 c20Instance;

    /// @dev The minimum investment a user is allowed to send
    uint256 MIN_INVESTMENT;

    /// @dev Temporary storage for user's ether balance before
    /// conversion takes place
    mapping (address => uint256) public userBalances;

    /// @dev Temporary storage for the time the user sent ether
    /// to this contract. This allows the forward pricing mechanism
    /// to work as this time will be compared with C20.previousUpdateTime
    /// to decide when the tokens can be redeemed
    mapping (address => uint256) public requestTime;

    /// @dev Emitted when a user has deposited ether into the contract
    /// @param sender The account which sent the ether
    /// @param amount The amount of ether that was sent
    event EtherDeposited(address indexed sender, uint256 amount);

    /// @dev Emitted when a user has converted deposited ether into C20 tokens
    /// @param sender The account which sent the ether
    /// @param amount The number of tokens the user gets after conversion
    event TokensPurchased(address indexed sender, uint256 amount);

    /// @dev Emitted when a refund occurs. This signals that the contract needs
    /// to be refilled with tokens
    /// @param sender The sender whose token conversion triggered the refund
    /// @param amount The ether value of the refund
    event RefundGiven(address indexed sender, uint256 amount);

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
    /// mechanisms.
    ///
    /// This function should be wrapped in the inheriting contract with the
    /// onlyActive modifier to ensure users do not deposit more ether while
    /// there are no tokens available in the contract.
    function _buy(address sender, uint256 amount) internal {
        require(
            amount >= MIN_INVESTMENT,
            "C20Invest: ether received below minimum investment"
        );
        requestTime[sender] = c20Instance.previousUpdateTime();
        userBalances[sender] += amount;
        emit EtherDeposited(sender, amount);
    }

    /// @dev Allows the user to redeem their tokens given the amount
    /// of ether the user had previously sent to this contract and
    /// the previous C20 price update.
    ///
    /// We first check if the C20 price has been updated since the time
    /// the user last sent ether to the contract. We then see if the user
    /// has a positive ether balance for conversion.
    /// We then proceed with calculating the number of tokens.
    ///
    /// The logic for the conversion of tokens is almost identical to
    /// the :sol:func:`buyTo` function in the C20 smart contract. We obtain the forward price
    /// by accessing the prices mapping within the C20 contract, using the
    /// user's requestTime as the key. We multiply the user's
    /// ether balance by the extracted price's numerator and divide by its
    /// denominator.
    ///
    /// A refund is also possible if the user had deposited more ether than
    /// tokens available in the smart contract. In this case, the remaining
    /// ether balance is transferred back to the user and the remainder of
    /// tokens within this contract transferred to their account.
    ///
    /// This function should be wrapped in the inheriting contract with the
    /// Suspendable mechanism. Upon refund the contract
    /// should then enter a suspended state until refilled with tokens and
    /// manually unsuspended.
    /// @return _refund Use this to check if there was a refund given, and
    /// if there was, suspend the contract
    function _getTokens() internal returns(uint256 _refund) {

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

        // Get the current price from the C20 instance and work out the
        // number of tokens the user can purchase given their current
        // balance
        (priceNumerator, priceDenominator) = c20Instance.prices(requestTime[msg.sender]);
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
        delete userBalances[msg.sender];

        // Perform token transfer
        c20Instance.transfer(msg.sender, numTokens);

        emit TokensPurchased(msg.sender, numTokens);

        // Perform a refund if there is one
        if (refund != 0) {
            msg.sender.transfer(refund);
            emit RefundGiven(msg.sender, refund);
        }
        return refund;
    }

}
