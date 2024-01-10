// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;


import {Script, console} from "forge-std/Script.sol";
import {EntryPoint} from "../src/core/EntryPoint.sol";

contract Deploy is Script{

    EntryPoint public entreypoint;

    function run()external{
        vm.startBroadcast();

        entreypoint = new EntryPoint();
        console.log(address(entreypoint));

        vm.stopBroadcast();

    }

}