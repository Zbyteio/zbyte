// SPDX-License-Identifier: MIT

// --.. -... -.-- - . 
// ███████╗██████╗ ██╗   ██╗████████╗███████╗
// ╚══███╔╝██╔══██╗╚██╗ ██╔╝╚══██╔══╝██╔════╝
//   ███╔╝ ██████╔╝ ╚████╔╝    ██║   █████╗  
//  ███╔╝  ██╔══██╗  ╚██╔╝     ██║   ██╔══╝  
// ███████╗██████╔╝   ██║      ██║   ███████╗
// ╚══════╝╚═════╝    ╚═╝      ╚═╝   ╚══════╝
// --.. -... -.-- - . 

pragma solidity ^0.8.9;

/// @title The ZBYT ERC20 Escrow contract
interface IEscrowERC20 {
    // errors
    /// @notice Caller is not a valid relay
    error InvalidRelay(address);
    /// @notice event (0xd6facdff): The callback received was invalid
    error InvalidCallbackMessage(uint256,uint256,uint256,uint256);
    /// @notice event (0xcd9d7bb0): The ack in callback received was not found
    error InvalidCallbackAck(uint256,bytes32,bool,uint256);
    /// @notice error (0xb3922495): Unauthorized caller.
    error UnAuthorized(address);
    /// @notice error (0xb3922495): Insufficient ERC20 deposit to cover approve and deposit cost.
    error InsufficientERC20DepositForGas(uint256,uint256);

    // events
    /// @notice event (0x1a40ce6d): vERC20 contract address is set
    event vERC20AddressSet(address,uint256);
    /// @notice event (0x95290bcc): Core relay wrapper contract address is set
    event RelayWrapperAddressSet(address);
    /// @notice event (0xcae09af7): ERC20 tokens deposited
    event ERC20Deposited(address,address,uint256,uint256,bytes32);
    /// @notice event (0x0583eefc): ERC20 tokens deposit failed
    event ERC20DepositFailed(address,address,uint256,uint256,bytes32);
    /// @notice event (0xf64578a8): ERC20 tokens deposit confirmed
    event ERC20DepositConfirmed(bytes32,bool,uint256);
    /// @notice event (0x8b923c21): ERC20 tokens withdrawn
    event ERC20Withdrawn(address,address,address,uint256,bytes32);
    /// @notice event (0x2b4d7cea): ERC20 tokens withdraw failed
    event ERC20WithdrawFailed(address,address,address,uint256,bytes32);
    /// @notice event (0xf5a60bd1): ERC20 tokens withdraw confirmed
    event ERC20WithdrawConfirmed(bytes32,bool,uint256);
    /// @notice event (0x1db696c9): The Treasury address is set
    event TreasuryAddressSet(address,address);
    /// @notice event (0x82b9d61d): ERC20 tokens deposit failed and refund issued to depositor
    event ERC20DepositFailedAndRefunded(bytes32,bool,uint256);
    /// @notice event (0x681edad8): Authorized worker registered.
    event ZbyteAuthorizedWorkerRegistered(address,bool);
    /// @notice event (0x8d8aaed3): ERC20 token value in native eth set.
    event ERC20TokenValueInNativeEthGweiSet(uint256);
    /// @notice event (0xb8f351d8): Approve and deposit cost for the combination of chainId and relay is set.
    event ApproveAndDepositCostInERC20Set(uint256,uint256,uint256);

    function getNonce() external view returns(uint256);
    function totalSupplyAllChains() external view returns (uint256);
    function totalSupply(uint256 chain_) external view returns (uint256);
    function asset() external view returns (address);
    function callbackHandler(uint256 chain_,
                            bytes32 ack_,
                            bool success_,
                            uint256  retval_)
        external returns(uint256);
}