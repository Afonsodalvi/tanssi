// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IWalletAccount {
    function initialize(address owner_) external;

    function setAllowed(address addr, bool allowed) external;
}
