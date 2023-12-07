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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./EscrowERC20.sol";

/// @title The ZBYT ERC20 Escrow contract
contract ZbyteEscrow is Ownable, Pausable, EscrowERC20 {

    constructor(address forwarder_,
                address zbyte_,
                address treasury_)
                EscrowERC20(forwarder_, IERC20(zbyte_)) {
        setTreasuryAddress(treasury_);
    }

    /// @notice Deposit ERC20 tokens to obtain vERC20 on target chain
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param receiver_ Recipient address for vERC20
    /// @param amount_ Amount of ERC20 deposited
    function deposit(uint256 relay_,
                      uint256 chain_,
                      address receiver_,
                      uint256 amount_)
                      public
                      whenNotPaused
                      returns (bool result) {
        return _deposit(relay_,chain_,receiver_,amount_);
    }

    /// @notice Withdraw ERC20 tokens by depositing vERC20 on target chain
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param vERC20Depositor_ Address to deposit vERC20
    /// @param receiver_ Recipient address for ERC20
    /// @dev The paymaster_ should be a valid paymaster (e.g., forwarder). All vERC20 held by paymaster is destroyed and equal ERC20 is deposited
    function withdraw(uint256 relay_,
                      uint256 chain_,
                      address vERC20Depositor_,
                      address receiver_)
                      whenNotPaused
                      public onlyAuthorized
                      returns (bool result) {
        return _withdraw(relay_,chain_,vERC20Depositor_,receiver_);
    }

    /// @notice callback handler to handle acknowledgement for deposit/withdraw
    /// @param chain_ Target chain identifier
    /// @param ack_ Unique hash of the submitted deposit/withdraw request
    /// @param success_ true if the deposit/withdraw was successful on remote
    /// @param retval_ The amount of tokens that were deposited/withdrawn
    function callbackHandler(uint256 chain_,
                            bytes32 ack_,
                            bool success_,
                            uint256  retval_)
        external
        returns(uint256) {
        return _callbackHandler(chain_,ack_,success_,retval_);

    }

    /// @notice Set the address of vERC20 on a given chain
    /// @param verc20_ vERC20 contract address
    /// @param chain_ chain id of the chain where vERC2o contract resides
    /// @dev nonce is incremented for every successful deposit or withdraw
    function setvERC20Address(address verc20_, uint256 chain_) public onlyOwner {
        _setvERC20Address(verc20_,chain_);
    }
    
    /// @notice Set the address of core relay wrapper
    /// @param wrapper_ Core relay wrapper contract address
    function setRelayWrapperAddress(address wrapper_) public onlyOwner {
        _setRelayWrapperAddress(wrapper_);
    }

    /// @notice Pauses the contract (mint, transfer and burn operations are paused)
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the paused contract
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice ERC2771 _msgSender override
    function _msgSender() internal view override(ZbyteContext,Context) returns (address sender) {
        return ZbyteContext._msgSender();
    }

    /// @notice ERC2771 _msgData override
    function _msgData() internal view override(ZbyteContext,Context) returns (bytes calldata) {
        return ZbyteContext._msgData();
    }
}