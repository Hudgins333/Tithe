// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Tithe
 * @notice An ERC-20 token with built-in tithing. Every transfer automatically
 *         routes a configurable percentage of the transferred amount to a
 *         designated tithe recipient (e.g., a church wallet, missions fund,
 *         benevolence address). The remainder goes to the intended recipient.
 *
 *         Built for Arc Testnet by Greg. Soli Deo gloria.
 */
contract Tithe {
    // --- ERC-20 storage ---
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Tithe configuration ---
    address public owner;
    address public titheRecipient;
    uint256 public titheBps; // basis points; 1000 = 10%
    bool public titheActive;

    uint256 public constant MAX_TITHE_BPS = 5000; // 50% hard cap
    uint256 public constant BPS_DENOMINATOR = 10000;

    // --- Stats ---
    uint256 public totalTithed;
    uint256 public titheCount;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event TitheRouted(
        address indexed from,
        address indexed intendedRecipient,
        address indexed titheRecipient,
        uint256 grossAmount,
        uint256 titheAmount,
        uint256 netAmount
    );
    event TitheRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event TitheBpsUpdated(uint256 oldBps, uint256 newBps);
    event TitheActiveUpdated(bool active);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    // --- Errors ---
    error NotOwner();
    error ZeroAddress();
    error TitheBpsTooHigh();
    error InsufficientBalance();
    error InsufficientAllowance();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _titheRecipient,
        uint256 _titheBps
    ) {
        if (_titheRecipient == address(0)) revert ZeroAddress();
        if (_titheBps > MAX_TITHE_BPS) revert TitheBpsTooHigh();

        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        titheRecipient = _titheRecipient;
        titheBps = _titheBps;
        titheActive = true;

        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transferWithTithe(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed < amount) revert InsufficientAllowance();
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }
        _transferWithTithe(from, to, amount);
        return true;
    }

    function _transferWithTithe(address from, address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        if (balanceOf[from] < amount) revert InsufficientBalance();

        bool shouldTithe = titheActive
            && to != titheRecipient
            && from != titheRecipient
            && titheBps > 0;

        if (shouldTithe) {
            uint256 titheAmount = (amount * titheBps) / BPS_DENOMINATOR;
            uint256 netAmount = amount - titheAmount;

            balanceOf[from] -= amount;
            balanceOf[titheRecipient] += titheAmount;
            balanceOf[to] += netAmount;

            totalTithed += titheAmount;
            titheCount += 1;

            emit Transfer(from, titheRecipient, titheAmount);
            emit Transfer(from, to, netAmount);
            emit TitheRouted(from, to, titheRecipient, amount, titheAmount, netAmount);
        } else {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
        }
    }

    function setTitheRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) revert ZeroAddress();
        address old = titheRecipient;
        titheRecipient = newRecipient;
        emit TitheRecipientUpdated(old, newRecipient);
    }

    function setTitheBps(uint256 newBps) external onlyOwner {
        if (newBps > MAX_TITHE_BPS) revert TitheBpsTooHigh();
        uint256 old = titheBps;
        titheBps = newBps;
        emit TitheBpsUpdated(old, newBps);
    }

    function setTitheActive(bool active) external onlyOwner {
        titheActive = active;
        emit TitheActiveUpdated(active);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address old = owner;
        owner = newOwner;
        emit OwnerTransferred(old, newOwner);
    }

    function previewTithe(uint256 grossAmount)
        external
        view
        returns (uint256 titheAmount, uint256 netAmount)
    {
        if (!titheActive || titheBps == 0) {
            return (0, grossAmount);
        }
        titheAmount = (grossAmount * titheBps) / BPS_DENOMINATOR;
        netAmount = grossAmount - titheAmount;
    }
}
