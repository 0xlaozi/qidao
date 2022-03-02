pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract simpleErc20 is ERC20Mintable, ERC20Detailed{
    constructor(uint256 initialBalance, string memory name, string memory symbol, uint8 decimals) ERC20Detailed(name, symbol, decimals) public {
        super.mint(msg.sender, initialBalance);

    }
}
