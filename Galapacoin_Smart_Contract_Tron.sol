pragma solidity ^0.5.4;
 
library SafeMath {

  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
}

contract Owned {
    address public owner;
  
    function owned() public  {
        owner = msg.sender;
    }
    constructor() payable public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    address public newOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyNewOwner() { 
      require(msg.sender != address(0)); 
      require(msg.sender == newOwner); 
      _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
      require(_newOwner != address(0)); 
      newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner {
      owner = newOwner;
      emit OwnershipTransferred(owner, newOwner);
    }

}

contract TRC20Interface {
  uint public totalSupply;
  function setTokenStatus(bool _status)  public returns (bool);
  function balanceOf(address who) public view returns (uint);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint);
  function approve(address _spender, uint _value) public returns (bool);
  function setFrozenAccount(address _to, bool _status) public returns (bool); 
  function mint(address _to, uint _value) public payable  returns (bool);
  function burn(address _from, uint256 _value) public payable returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

}

contract TRC20 is TRC20Interface,Owned {
  using SafeMath for uint;
  bool isEnabled;

  mapping(address => bool) frozen;
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  
  function setTokenStatus(bool _status) onlyOwner public returns (bool success) {
    isEnabled = _status;
    return true;
  }

  function setFrozenAccount(address _to, bool _status) onlyOwner public returns (bool success) {
    frozen[_to] = _status;
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    require(_owner != address(0));
    return balances[_owner];
  }

  function _transfer(address _from, address _to, uint _value) internal { 
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) { 
    require(isEnabled);
    require(frozen[_from] != true);
    require(frozen[_to] != true);
    require(_from != address(0)); 
    require(_to != address(0)); 
    require(_value <= balances[_from]); 
    require(_value <= allowed[_from][msg.sender]); 
    _transfer(_from, _to, _value); 
    return true; 
  }

  function transfer(address _to, uint256 _value) public returns (bool ) { 
    require(isEnabled);
    require(frozen[_to] != true);
    require(_to != address(0)); 
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value); 
    return true; 
  }
  
}

contract TRC20Token is Owned, TRC20 {

  mapping (address => mapping (address => uint)) allowed;
  mapping(address => bool) frozen;

  function approve(address _spender, uint _value) public returns (bool success){
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function mint(address _to, uint _value) public payable onlyOwner returns (bool success) {
    require(_to != address(0));
    require(frozen[_to] != true);
    balances[_to] = balances[_to].add(_value);
    totalSupply = totalSupply.add(_value);
    return true;
  }

  function burn(address _from, uint256 _value) public payable onlyOwner returns (bool success)  {
    require(_from != address(0));
    require(frozen[_from] != true);
    require(balances[_from] >= _value);  
    balances[_from] = balances[_from].sub(_value);  
    totalSupply = totalSupply.sub(_value);
    return true;
  }

}

contract UCoin is TRC20Token {
    string public constant name = "Galapacoin";
    string public constant symbol = "GLPC";
    uint public constant decimals = 18;
    
    constructor () public  {
        isEnabled = true;
        totalSupply = 10000000000 * (10 ** decimals);
        balances[msg.sender] = totalSupply;
	      emit Transfer(address(0x0), msg.sender, totalSupply);
    }
    
    function () external payable {
        revert();
    }
    
}
