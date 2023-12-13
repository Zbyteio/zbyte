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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interface/dplat/IvERC20.sol";
import "../utils/Auth.sol";

/// @title The ZBYT vERC20 contract
/// @dev The ZBYT vERC20 contract
contract ZbyteVToken is Ownable, Pausable, ERC20, AuthSimple, IvERC20 {
    // errors
    /// @notice error (0xd92e233d): Address is address(0)
    error ZeroAddress();
    /// @notice error (0xbf064619): Contract cannot receive ether
    error CannotSendEther();

    // events
    /// @notice event (0xcdb1d336) ZbyteDPlat address is set
    event ZbyteDPlatAddressSet(address);

    // Address to transfer 'burnt' tokens
    address private burner;
    // Address of the DPlat contract
    address private dplat;

    /// @notice ZBYT ERC20 constructor
    /// @param burner_ Burn account address (Tokens are locked here, not destroyed)
    constructor(address burner_) ERC20("vZbyte", "vZBYT") {
        burner = burner_;
    }

    /// @notice Pauses the contract (mint, transfer and burn operations are paused)
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the paused contract
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Set the DPlat address
    /// @param dplat_ DPlat contract address
    function setZbyteDPlatAddress(address dplat_) public onlyOwner {
        if(dplat_ == address(0)) {
            revert ZeroAddress();
        }
        dplat = dplat_;

        emit ZbyteDPlatAddressSet(dplat_);
    }

    /// @notice Transfer vERC20 from caller's account to receiver's account
    /// @param to_ Receiver account address
    /// @param value_ Amount of tokens to be transferred
    /// @dev requiresAuth ensures that this call can be complely disabled, or only specific accounts can call
    function transfer(address to_, uint256 value_)
        public override(IERC20, ERC20)
        requiresAuth whenNotPaused
        returns (bool) {
        ERC20.transfer(to_, value_);
        return true;
    }

    /// @notice Transfers tokens from a specified address to another address.
    /// @param from_ The address to transfer tokens from
    /// @param to_ The address to transfer tokens to
    /// @param value_ The amount of tokens to transfer
    /// @dev requiresAuth ensures that this call can be complely disabled, or only specific accounts can call
    ///  Allowing only specific accounts to perform transferFrom allows controlled transfer of vERC20 in future
    function transferFrom(address from_, address to_, uint256 value_)
        public override(IERC20, ERC20)
        requiresAuth whenNotPaused
        returns (bool) {
        ERC20.transferFrom(from_, to_, value_);
        return true;
    }

    /// @notice mint vZBYT ERC20
    /// @param to_ Receiver address
    /// @param amount_ Amount to mint to the address(to_) and approve to dplat
    /// @dev The forwarder charges user in this ERC20 token for the contract call.  Approve the tokens to dplat at mint itself.
    function mint(address to_, uint256 amount_)
        external
        requiresAuth whenNotPaused
        returns(uint256) {
        if(dplat == address(0)) {
            revert ZeroAddress();
        }
        ERC20._mint(to_, amount_);
        uint256 _allowance = ERC20.allowance(to_, dplat);
        ERC20._approve(to_, dplat, _allowance + amount_);
        return amount_;
    }

    /// @notice Transfer vERC20 to 'burner' address
    /// @param from_ Sender address to burn tokens from
    /// @param amount_ Amount to burn
    /// @dev requiresAuth ensures that this call can be complely disabled, or only specific accounts can call
    function burn(address from_, uint256 amount_) external
        requiresAuth whenNotPaused
        returns(uint256) {
        _transfer(from_, burner, amount_);
        return amount_;
    }

    /// @notice Destroy vERC20
    /// @param from_ Address from which tokens are destroyed
    /// @dev This is called during withdraw / reconciliation only.  Withdraw is allowed only from the paymaster or burner address
    function destroy(address from_)
        external
        requiresAuth whenNotPaused
        returns(uint256) {
        uint256 _amount = this.balanceOf(from_);
        _burn(from_, _amount);
        return _amount;
    }

    /// @notice receive function (reverts)
    receive() external payable {
       revert CannotSendEther();
    }
}
