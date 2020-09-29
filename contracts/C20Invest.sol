// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.0;

import "./c20_base/C20.sol";
import "./math/SafeMathNew.sol";
import "./proxy/Initializable.sol";

/// @title C20InvestBase Smart Contract
/// @author Invictus Capital
/// @notice Base Contract for C20 resale
/// @dev A smart contract that acts as an exchange for the
/// purchase of :sol:contract:`C20` tokens. The requirements are that we
/// use forward pricing and that the contract is upgradeable.
/// This contract represents the implementation logic for the
/// token purchase and will be where transactions are forwarded to
/// from the proxy contract.
contract C20Invest is Initializable {
    using SafeMathNew for uint256;

    /// @dev State variable representing owner of the contract
    address private _owner;
    
    /// @dev State variable for C20 instance
    C20 private _c20Instance;
    
    /// @dev Track unconverted ether to prevent accidental withdrawal
    /// by owner
    uint256 public unconvertedEther = 0;

    /// @dev The minimum investment a user is allowed to send
    uint256 public minInvestment;

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
    
    /// @dev Emitted when all tokens are transferred out of this
    /// contract
    /// @param sender The account which triggered the transfer
    /// @param amount The number of tokens transferred
    event AllTokensTransferred(address indexed sender, uint256 amount);

    
    /// @dev Initializer for this contract
    /// @param owner The address of the owner of the contract
    /// @param c20Address The address of the currently active
    /// C20 smart contract. Required to initialize the C20
    /// instance
    function initialize (address owner, address c20Address)
    external
    initializer {
        _owner = owner;
        _c20Instance = C20(payable(c20Address));
        minInvestment = 0.1 ether;
    }

    /// @dev Allows changing the address of the C20 contract in the
    /// event of an upgrade. The inheriting contract should wrap this
    /// function with onlyOwner to protect from it being called by
    /// anyone.
    /// @param c20Address The address of the currently active
    /// C20 smart contract
    function setC20Address(address c20Address) external onlyOwner {
        _c20Instance = C20(payable(c20Address));
    }

    /// @dev The main function called by receive(). Records the
    /// user's balance and the current C20 previousUpdateTime
    /// required for token conversion and forward pricing
    /// mechanisms.
    ///
    /// This function is callable even when there are no tokens
    /// within this contract.
    function buy() public payable {
        require(
            msg.value >= minInvestment,
            "C20Invest: ether received below minimum investment"
        );
        requestTime[msg.sender] = _c20Instance.previousUpdateTime();
        userBalances[msg.sender] = userBalances[msg.sender].add(msg.value);
        unconvertedEther = unconvertedEther.add(msg.value);
        emit EtherDeposited(msg.sender, msg.value);
    }

    /// @dev Allows the user to redeem their tokens given the amount
    /// of ether the user had previously sent to this contract and
    /// the following C20 price update.
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
    /// tokens available in the smart contract. In this case, the entire
    /// ether balance is transferred back to the user and the remainder of
    /// tokens within this contract is kept by the contract instead of being
    /// transferred to the user.
    function getTokens() external {

        uint256 contractTokenBalance = _c20Instance.balanceOf(address(this));
        uint256 numTokens = 0;
        uint256 priceNumerator;
        uint256 priceDenominator;
        uint256 refund = 0;
        bool success = false;
        bytes memory returnData;
        // Forward pricing mechanism
        require(
            requestTime[msg.sender] < _c20Instance.previousUpdateTime(),
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
        (priceNumerator, priceDenominator) = _c20Instance.prices(requestTime[msg.sender]);
        numTokens = priceNumerator.mul(userBalances[msg.sender]).div(priceDenominator);

        // Revert the entire transaction if we do not have sufficient
        // tokens
        if (numTokens > contractTokenBalance) {
            refund = userBalances[msg.sender];
            unconvertedEther = unconvertedEther.sub(refund);
            delete userBalances[msg.sender];
            emit RefundGiven(msg.sender, refund);
            
            (success, returnData) = msg.sender.call{ value: refund }("");
            require(success, "C20Invest: getTokens refund error");
            
        } else {
            // Zero balance to prevent reentrancy attacks
            // solhint-disable-next-line reentrancy
            unconvertedEther = unconvertedEther.sub(userBalances[msg.sender]);
            delete userBalances[msg.sender];
            emit TokensPurchased(msg.sender, numTokens);
            
            // Perform token transfer
            success = _c20Instance.transfer(msg.sender, numTokens);
            require(success, "C20Invest: token transfer failed");
            
        }

    }
    
    /// @dev Helper function to get balance of ether in this contract.
    /// Automatically subtracts unconvertedEther to give available balance
    /// for withdrawal.
    /// @return balance The current ether balance within the contract
    function getContractEtherBalance()
    public
    view
    onlyOwner
    returns (uint256 balance) {
        if(unconvertedEther > address(this).balance){
            return 0;
        } else {
            return address(this).balance.sub(unconvertedEther); 
        }
    }

    /// @dev Allows owner to withdraw ether stored. Automatically
    /// reverts if amount is greater than contract ether balance
    /// minus unconvertedEther.
    /// @param amount The amount to withdraw in wei
    function withdrawETHBalance(uint256 amount) external onlyOwner
    {
        require(
            amount <= getContractEtherBalance(),
            "C20Invest: amount greater than available balance"
        );
        bool success = false;
        bytes memory returnData;
        
        (success, returnData) = msg.sender.call{value: amount}("");
        require(success, "C20Invest: withdrawETHBalance failed");
    }

    /// @dev Allows owner to withdraw all ether stored. 
    function removeAllEther() external onlyOwner
    {
        bool success = false;
        bytes memory returnData;
        
        (success, returnData) = msg.sender.call{value: address(this).balance}("");
        require(success, "C20Invest: removeAllEther failed");

    }

    /// @dev Transfers all tokens within this account to the
    /// owner.
    function removeTokens() external onlyOwner {
        uint256 tokenBalance = _c20Instance.balanceOf(address(this));
        bool success = false;
        require(tokenBalance > 0, "C20Invest: contract has zero token balance");
        
        emit AllTokensTransferred(msg.sender, tokenBalance);
        
        success = _c20Instance.transfer(msg.sender, tokenBalance);
        require(success, "C20Invest: token transfer failed");
        
    }

    /// @dev The receive function is triggered when ether is sent to the
    /// contract. It is just a simple wrapper for buy().
    receive() external payable {
        buy();
    }
    
    /// @dev Retrieve the owner of the contract
    function getOwner() external view returns (address) {
        return _owner;
    }

    /// @dev Guard against non-owners calling privileged functions
    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "C20Invest: caller is not the owner"
        );
        _;
    }

    //#########################################################################//
    // Next versions' code and state variables should only go after here. Do   //
    // not change any of the preceding code or inherited contract code. This   //
    // will likely cause errors in the storage layout of the proxy. This       //
    // is vitally important for C20InvestInitializable as this is the contract //
    // that is deployed behind the proxy.                                      //
    //#########################################################################//
    

}
