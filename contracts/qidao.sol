pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, ERC20Detailed {
     constructor() public ERC20Detailed("Qi Dao", "QI", 18) {
        _mint(msg.sender, 200000000 * (10 ** uint256(super.decimals())));
    }
}