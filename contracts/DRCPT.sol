pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract DRCPT is Ownable, ERC20Burnable, ERC20Detailed {

    address public releaseAgent;

    bool public released = false;

    mapping (address => bool) public transferAgents;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 amount
    )
        ERC20()
        ERC20Detailed(name, symbol, decimals)
        Ownable()
        public
    {
        require(amount > 0, "amount has to be greater than 0");
        uint256 totalSupply = amount.mul(10 ** uint256(decimals));
        releaseAgent = msg.sender;
        _mint(msg.sender, totalSupply);
    }

    modifier canTransfer(address _sender) {
        require(released || transferAgents[_sender]);
        _;
    }

    modifier inReleaseState(bool releaseState) {
        require(releaseState == released);
        _;
    }

    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent);
        _;
    }

    function setReleaseAgent(address addr) public onlyOwner inReleaseState(false) {
        require(addr != address(0x0));
        releaseAgent = addr;
    }

    function release() public onlyReleaseAgent inReleaseState(false)  {
        released = true;
    }

    function setTransferAgent(address addr, bool state) public onlyOwner inReleaseState(false) {
        require(addr != address(0x0));
        transferAgents[addr] = state;
    }

    function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public {
        return super.burn(_value);
    }

    function burnFrom(address _from, uint256 _value) public {
        return super.burnFrom(_from, _value);
    }
}
