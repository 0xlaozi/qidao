pragma solidity ^0.5.0;

interface PriceSource {
	function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}