// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {ReentrancyGuardUpgradeable} from "@upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@upgradeable/contracts/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@upgradeable/contracts/access/OwnableUpgradeable.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract SecurityUpgradeable is
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Storage Variables
    /// -----------------------------------------------------------------------

    struct Permission{
        uint256 until;
        uint256 limit;
    }

    mapping(address => mapping(bytes4 => Permission)) internal s_allowed;

    /// -----------------------------------------------------------------------
    /// Modifiers (or internal functions as modifiers)
    /// -----------------------------------------------------------------------

    function __onlyOwner() internal view virtual onlyOwner {}

    function __whenNotPaused() internal view virtual whenNotPaused {}

    /// -----------------------------------------------------------------------
    /// State-change public/external functions
    /// -----------------------------------------------------------------------

    /* solhint-disable func-name-mixedcase */
    function __Security_init(address owner_) internal onlyInitializing {
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init(owner_);
        _allowUnlimitedPermission(owner_);
    }

    /// -----------------------------------------------------------------------
    /// State-change internal functions
    /// -----------------------------------------------------------------------

    
    function _allowUnlimitedPermission(address _address) internal {
        s_allowed[_address][0xffffffff] = Permission({until: type(uint256).max, limit : type(uint256).max});
    }

    function _checkAllow(address _addr, bytes4 _func) internal returns (bool){
        if(s_allowed[_addr][0xffffffff].until > 0){
            return true;
        } else if(s_allowed[_addr][_func].until >=  block.timestamp) {
            s_allowed[_addr][_func].until = 0;
            return true;
        }else if(s_allowed[_addr][_func].limit >  0) {
            s_allowed[_addr][_func].limit--;
            return true;
        }else{
            revert("Not allowed");
        }
    }

    /// -----------------------------------------------------------------------
    /// State-change internal functions
    /// -----------------------------------------------------------------------

    function allowUnlimitedPermission(address _address) external virtual returns (bool){
        _checkAllow(msg.sender, 0x3a7fb4a7);
        _allowUnlimitedPermission(_address);
        return true;
    }
    function allowUntil(address _address, bytes4 _func, uint256 _until) external virtual returns (uint256){
        _checkAllow(msg.sender, 0xbb747df3);
        return s_allowed[_address][_func].until = _until;
    }
    function allowLimit(address _address, bytes4 _func, uint256 _limit) external virtual returns(uint256){
        _checkAllow(msg.sender, 0x2d0355db);
        return s_allowed[_address][_func].limit = _limit;
    }


    /// -----------------------------------------------------------------------
    /// view functions
    /// -----------------------------------------------------------------------
    
    function getAllowed(address _addr) external view returns(bool) {        
        return s_allowed[_addr][0xffffffff].until > 0;       
    }

    function getAllowed(address _addr, bytes4 _func) external view returns(bool) {
        if(s_allowed[_addr][0xffffffff].until > 0){
            return true;
        } else if(s_allowed[_addr][_func].until >=  block.timestamp) {
            return true;
        }else if(s_allowed[_addr][_func].limit >  0) {
            s_allowed[_addr][_func].limit;
            return true;
        }
        return false;
    }

    function getAllowedUntil(address addr, bytes4 _function) external view returns (uint256) {
        return s_allowed[addr][_function].until;
    }
    function getAllowedLimit(address addr, bytes4 _function) external view returns (uint256) {
        return s_allowed[addr][_function].limit;
    }

}