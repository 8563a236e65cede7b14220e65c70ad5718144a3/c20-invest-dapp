// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.0;

import './SafeMath.sol';
import './Token.sol';


contract StandardToken is Token, SafeMath {

    uint256 public totalSupply;

    // TODO: update tests to expect throw
    function transfer(address _to, uint256 _value) public override virtual onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // TODO: update tests to expect throw
    function transferFrom(address _from, address _to, uint256 _value) public override virtual onlyPayloadSize(3) returns (bool success) {
        require(_to != address(0), "StandardToken: _to Zero Address");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "StandardToken: allowance less than value");
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public override virtual view returns (uint256 balance) {
        return balances[_owner];
    }

    // To change the approve amount you first have to reduce the addresses'
    //  allowance to zero by calling 'approve(_spender, 0)' if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) public override virtual onlyPayloadSize(2) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue);

        return true;
    }

    function allowance(address _owner, address _spender) public override virtual view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}
