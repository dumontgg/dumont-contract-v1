// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IAirdrop {
    event ClaimerAdded(address indexed _claimer);

    event ClaimAmountChanged(uint256 indexed _from, uint256 indexed _to);

    event Claimed(address indexed _claimer, uint256 _amount);

    error NotEligible(address _caller);
}
