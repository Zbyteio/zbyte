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

import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title The Zbyte core forwarder contract
/// @dev The Zbyte core forwarder contract.
contract ZbyteForwarderCore is Ownable, MinimalForwarder, ReentrancyGuard {

    // errors
    /// @notice error (0xd92e233d): Address is address(0)
    error ZeroAddress();

    // events
    /// @notice event (0xa6cc9cbb): DPLAT address is set
    event ZbyteAddressSet(address);
    /// @notice event (0x0a787863): Token forwarder address is set
    event ZbyteTokenForwarderAddressSet(address);
    /// @notice event (0x14229a64) Escrow address is set
    event EscrowAddressSet(address);

    // DPLAT ERC20 address
    /// @notice DPLAT ERC20 contract address
    address public zByteAddress;
    /// @notice Forwarder of ERC20 token contract
    MinimalForwarder zbyteTokenForwarder;
    // Escrow address
    /// @notice Escrow contract address
    address public escrowAddress;

    bytes4 private approvesig = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private depositsig = bytes4(keccak256("deposit(uint256,uint256,address,uint256)"));


    /// @notice Set DPLAT ERC20 address
    /// @param zbyte_ DPLAT ERC20 contact address
    function setZbyteAddress(address zbyte_) public onlyOwner {
        if(zbyte_ == address(0)) {
            revert ZeroAddress();
        }
        zByteAddress = zbyte_;

        emit ZbyteAddressSet(zbyte_);
    }

    /// @notice Set DPLAT ERC20 Forwarder address
    /// @param forwarder_ DPLAT ERC20 forwarder contact address
    function setZbyteTokenForwarderAddress(address forwarder_) public onlyOwner {
        if(forwarder_ == address(0)) {
            revert ZeroAddress();
        }
        zbyteTokenForwarder = MinimalForwarder(forwarder_);

        emit ZbyteTokenForwarderAddressSet(forwarder_);
    }

    /// @notice Set Zbyte Escrow address
    /// @param escrow_ Zbyte Escrow contract address
    function setEscrowAddress(address escrow_) public onlyOwner {
        if(escrow_ == address(0)) {
            revert ZeroAddress();
        }
        escrowAddress = escrow_;

        emit EscrowAddressSet(escrow_);
    }

    /// @notice Perform approve and depost of Zbyte in single call
    /// @param reqApprove_ ForwardRequest for the approve call
    /// @param signatureApprove_ Signature of the approve call params
    /// @param reqDeposit_ ForwardRequest for the deposit call
    /// @param signatureDeposit_ Signature of the deposit call params
    /// @return success returns true of approve and deposit are successful
    /// @dev Allows gasless approve+deposit of DPLAT token to be used at https://dplat.zbyte.io
    function approveAndDeposit(ForwardRequest calldata reqApprove_, bytes calldata signatureApprove_,
                     ForwardRequest calldata reqDeposit_, bytes calldata signatureDeposit_)
        public
        payable
        nonReentrant
        returns (bool success)
    {
        bytes memory _returndata;
        require(reqApprove_.from == reqDeposit_.from, "approveAndDeposit: Invalid from addresses");
        require(reqApprove_.to == address(zByteAddress)
                && bytes4(reqApprove_.data[:4]) == approvesig
                && address(bytes20(reqApprove_.data[16:36])) == escrowAddress, "approveAndDeposit: Invalid approve data");
        require(reqDeposit_.to == address(escrowAddress)
                && bytes4(reqDeposit_.data[:4]) == depositsig, "approveAndDeposit: Invalid deposit data");

        (success, _returndata) = zbyteTokenForwarder.execute(reqApprove_, signatureApprove_);
        require(success,"Approve fail");
        (success, _returndata) = execute(reqDeposit_, signatureDeposit_);
        require(success, "Deposit fail");

        return success;
    }
}
