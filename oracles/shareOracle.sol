// contracts/shareOracle.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../PriceSource.sol";

contract shareOracle {

    using SafeMath for uint256;

	// this should just be vieweing a chainlink oracle's price
	// then it would check the balances of that contract in the token that its checking.
	// it should return the price per token based on the camToken's balance

    PriceSource public priceSource;
    ERC20 public underlying;
    ERC20 public shares; 

    uint256 public fallbackPrice;

    event FallbackPrice(
         uint80 roundId, 
         int256 price,
         uint256 startedAt,
		 uint256 updatedAt, 
		 uint80 answeredInRound
		 );

// price Source gives underlying price per token
// shareToken should hold underlying and we need to calculate a PPS

    constructor(address _priceSource, address _underlying, address _shares) public {
    	priceSource = PriceSource(_priceSource);
    	underlying  = ERC20(_underlying);
    	shares 		= ERC20(_shares);
    }

    // to integrate we just need to inherit that same interface the other page uses.

	function latestRoundData() public view
		returns 
			(uint80 roundId,
			 int256 answer,
			 uint256 startedAt,
			 uint256 updatedAt, 
			 uint80 answeredInRound
			){
		// we should passthrough all the data from the chainlink call. This would allow for transparency over the information sent.
		// Then we can filter as needed but this could be a cool standard we use for share-based tokens (like the compounding tokens)

		// check how much underlying does the share contract have.
		// underlying.balanceOf(address(shares))

		// then we check how many shares do we have outstanding
		// shares.totalSupply()

		// now we divide the total value of underlying held in the contract by the number of tokens

        (
         uint80 roundId, 
         int256 price,
         uint256 startedAt,
		 uint256 updatedAt, 
		 uint80 answeredInRound
		 ) = priceSource.latestRoundData();

        uint256 _price;

        if(price>0){
        	_price=uint256(price);
        } else {
	    	_price=fallbackPrice;
        }

		uint256 newPrice = ((underlying.balanceOf(address(shares))).mul(_price).div(shares.totalSupply()));
		
		return(roundId, int256(newPrice), startedAt, updatedAt, answeredInRound);
	}

	function getUnderlying() public view returns (uint256, uint256) {
		return (underlying.balanceOf(address(shares)), shares.totalSupply());
	}

	function updateFallbackPrice() public {
        (
         uint80 roundId, 
         int256 price,
         uint256 startedAt,
		 uint256 updatedAt, 
		 uint80 answeredInRound
		 ) = priceSource.latestRoundData();

		if (price > 0) {
			fallbackPrice = uint256(price);
	        emit FallbackPrice(roundId,price,startedAt,updatedAt,answeredInRound);
        }
 	}
}
