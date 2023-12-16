// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
// import {HelperConfig} from "./HelperConfig.s.sol";
import {WalletAccount} from "../src/WalletAccount.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract DeployWalletAccount is Script {
   // HelperConfig public config;

    WalletAccount public account;

    address public MPC = 0x98cbE6Fa08060f550Daf0C8E9FaCC5F12eb75F64;

    address entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    address owner = 0xAaa7cCF1627aFDeddcDc2093f078C3F173C46cA4;
    
    function run() public {
         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        account = new WalletAccount{salt: bytes32("Omnes12")}();
        
        UpgradeableBeacon accountBeacon = new UpgradeableBeacon{salt: bytes32("Omnes12")}(
            address(account),
            vm.addr(deployerPrivateKey)
        );

        accountBeacon.transferOwnership(MPC);

         vm.stopBroadcast();
    }
}
