// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function getConversionRate(
        uint ethAmount,
        AggregatorV3Interface priceFeed
    ) public view returns (uint) {
        uint ethamountInUsd = (getPrice(priceFeed) * ethAmount) / 1e18;
        return ethamountInUsd;
    }
}
