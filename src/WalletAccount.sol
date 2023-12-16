// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {BaseAccount, IEntryPoint} from "./BaseAccount.sol";
import {SecurityUpgradeable} from "./SecurityUpgradeable.sol";
import {UserOperation} from "./UserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TokenCallbackHandler} from "./TokenCallbackHandler.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract WalletAccount is
    BaseAccount,
    TokenCallbackHandler,
    SecurityUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Libraries
    /// -----------------------------------------------------------------------

    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;

    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    error WalletAccount__CallerNotOwner();

    error WalletAccount__CallerNotAllowed();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Executed(address indexed caller);

    event BatchExecuted(address indexed caller);

    event DepositWithdrawnTo(
        address indexed caller,
        address indexed to,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Storage/state variables
    /// -----------------------------------------------------------------------

    /* solhint-disable var-name-mixedcase, private-vars-leading-underscore */
    address private immutable i_entryPoint;

    address private immutable i_factory;

    address private immutable i_management;

    /// -----------------------------------------------------------------------
    /// Modifiers (or internal functions as modifiers)
    /// -----------------------------------------------------------------------

    function __onlyOwnerOrFactoryOrManagement() internal view {
        if (
            msg.sender != owner() &&
            msg.sender != i_factory &&
            msg.sender != i_management
        ) {
            revert WalletAccount__CallerNotAllowed();
        }
    }

    function __requireFromEntryPointOrManagement() internal view {
        require(
            msg.sender == address(entryPoint()) || msg.sender == i_management,
            "account: not from EntryPoint or Management"
        );
    }

    /// -----------------------------------------------------------------------
    /// Receive function
    /// -----------------------------------------------------------------------

    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        i_entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
        i_factory = 0x58CB45f355cB1C686A57fF63058b1C87634B3137;
        i_management = 0x3Be33092E4a933aFD17fB714a8623da52f55E07e;
        _allowUnlimitedPermission(i_factory);
        _allowUnlimitedPermission(i_management);
        _disableInitializers();
    }

    /// -----------------------------------------------------------------------
    /// State-change public/external functions
    /// -----------------------------------------------------------------------

    function initialize(address owner_) external initializer {
        __Security_init(owner_);
        _allowUnlimitedPermission(msg.sender);
        _allowUnlimitedPermission(i_entryPoint);
    }

    function entryPoint()
        public
        view
        override(BaseAccount)
        returns (IEntryPoint)
    {
        return IEntryPoint(i_entryPoint);
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        __requireFromEntryPointOrManagement();
        _call(dest, value, func);

        emit Executed(tx.origin);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) external {
        __requireFromEntryPointOrManagement();
        require(
            dest.length == func.length && dest.length == value.length,
            "wrong array lengths"
        );
        for (uint256 i = 0; i < dest.length; ) {
            _call(dest[i], value[i], func[i]);
            unchecked {
                ++i;
            }
        }

        emit BatchExecuted(tx.origin);
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public {
        _checkAllow(msg.sender, 0x4d44560d);
        //_requireFromEntryPoint();
        entryPoint().withdrawTo(withdrawAddress, amount);

        emit DepositWithdrawnTo(tx.origin, withdrawAddress, amount);
    }

    function setAllowed(address addr, bool allowed) external nonReentrant {
        //_checkAllow(msg.sender, 0x4697f05d);
        __onlyOwnerOrFactoryOrManagement();
        _allowUnlimitedPermission(addr);
    }

    /// -----------------------------------------------------------------------
    /// State-change internal/private functions
    /// -----------------------------------------------------------------------

    function _call(address target, uint256 value, bytes memory data) internal {
        //_checkAllow(msg.sender, 0x734cd1e2);
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// View public/external functions
    /// -----------------------------------------------------------------------

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    function getSignatureRecover(
        bytes32 userOpHash,
        bytes calldata signature
    ) external view returns (address, bool, uint256) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        return (
            hash.recover(signature),
            s_allowed[hash.recover(signature)][0xffffffff].until > 0,
            SIG_VALIDATION_FAILED
        );
    }

    function getFactory() external view returns (address) {
        return i_factory;
    }

    function getManagement() external view returns (address) {
        return i_management;
    }

    /// -----------------------------------------------------------------------
    /// View internal/private functions
    /// -----------------------------------------------------------------------

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override(BaseAccount) returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address recovered = hash.recover(userOp.signature);
        if (
            s_allowed[recovered][0xffffffff].until == 0 && owner() != recovered
        ) {
            return SIG_VALIDATION_FAILED;
        }
        return 0;
    }
}
