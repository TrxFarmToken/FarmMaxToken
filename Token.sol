pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public payable returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public payable returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Token is ERC20Interface{
    using SafeMath for uint;

    uint256 public totalSupply;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    address public owner;

    constructor (
            uint256 _initialAmount,
            string _tokenName,
            uint8 _decimalUnits,
            string _tokenSymbol
        ) public{
            owner = msg.sender;
            balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
            totalSupply = _initialAmount;                        // Update total supply
            name = _tokenName;                                   // Set the name for display purposes
            decimals = _decimalUnits;                            // Amount of decimals for display purposes
            symbol = _tokenSymbol;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public payable returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //bonus
    uint public totalFrozen = 0x00;
    uint public freezeDays = 10 minutes;
    mapping (address => uint256) public freezeBalance;
    mapping (address => uint256) public lockBalance;
    mapping (address => uint256) public unfreezeTime;
    event Freeze(address _from, uint8 _event_id, uint _amount);
    event Withdraw(address _from, address _to, uint _amount);
    function setFreezeDays(uint value) public onlyOwner returns (bool) {
        freezeDays = value * 1 days;
        return true;
    }

    function freeze(uint amount) public returns (bool) {
        require(amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        freezeBalance[msg.sender] = freezeBalance[msg.sender].add(amount);
        totalFrozen = totalFrozen.add(amount);
        emit Freeze(msg.sender, 1, amount);
        return true;
    }

    function unFreeze(uint amount) public returns (bool) {
        require(amount > 0);
        require(amount == freezeBalance[msg.sender]);

        freezeBalance[msg.sender] = 0x00;
        totalFrozen = totalFrozen.sub(amount);
        lockBalance[msg.sender] = lockBalance[msg.sender].add(amount);
        unfreezeTime[msg.sender] = now.add(freezeDays);
        emit Freeze(msg.sender, 2, amount);
        return true;
    }
    function withdraw(address _to, uint amount) public returns (bool) {
         require(amount > 0);
         require(amount == lockBalance[msg.sender]);
         require(now >= unfreezeTime[msg.sender]);
         require(unfreezeTime[msg.sender] > freezeDays);

         lockBalance[msg.sender] = 0x00;
         balances[_to] = balances[_to].add(amount);
         emit Withdraw(msg.sender, _to, amount);
         return true;
    }

    function burn(uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
}