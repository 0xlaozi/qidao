pragma solidity 0.7.6;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor () ERC20("Qi Dao", "QI") {
        _mint(msg.sender, 200000000 * (10 ** uint256(decimals())));
    }
}