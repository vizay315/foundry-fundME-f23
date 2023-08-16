// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private addressToAmountFunded;
    address[] private s_funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Minimum 5USD"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function cheaperWithdraw() public onlyOwner {
        uint fundersLength = s_funders.length;
        for (uint i = 0; i < fundersLength; i++) {
            address funder = s_funders[i];
            addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    function withdraw() public onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");

        for (uint i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /*
     * View / Pure functions (Getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint) {
        return addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
