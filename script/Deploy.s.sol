// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {Script, console} from "forge-std/Script.sol";
import {EntryPoint} from "../src/core/EntryPoint.sol";

contract Deploy is Script{

    EntryPoint public entreypoint;

    function run()external{
        entreypoint = new EntryPoint();
        console.log(address(entreypoint));
    }

}