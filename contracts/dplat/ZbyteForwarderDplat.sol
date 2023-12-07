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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/dplat/IZbyteDPlat.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title The ZBYT Dplat forwarder contract
/// Todo: Integrate chargeAndBurnZbyteVToken and refundZbyteVToken with ZbyteDPlat
contract ZbyteForwarderDPlat is Ownable, MinimalForwarder, ReentrancyGuard {
    /// events
    /// @notice event (0xeae099e1): Forwarder address is set.
    event ForwarderDplatSet(address);
    /// @notice event (0x6342abcf): Forwarder minimum processing gas is set.
    event ForwarderDplatMinimumProcessingGasSet(uint256);
    /// @notice event (0xe1554bda): Forwarder worker is registered.
    event ForwarderDplatWorkerRegistered(address,bool);
    /// @notice event (0xe5cac075): Refund Eth to payer.
    event RefundEth(address,uint256);
    /// @notice event (0x5c3206c6): Execute result and return data
    event ZbyteForwarderDPlatExecute(bool,bytes);
    /// @notice event (0x1f32728a): Forwarder post exec gas is set.
    event ForwarderDplatPostExecGasSet(uint256);

    /// errors
    /// @notice error (0xd92e233d): Address is zero. 
    error ZeroAddress();
    /// @notice error (0xfb3dd446): Array sizes don't match.
    error ArraySizeMismatch(uint256, uint256);
    /// @notice error (0xf9309a09): Not enough ether sent the function.
    error NotEnoughEtherSent(uint256, uint256);
    /// @notice error (0xb7da4a55): Failed to send ether.
    error FailedToSendEther(address,uint256,bytes);
    /// @notice error (0x9059e055): Not a worker.
    error NotAWorker(address);

    // Minimum processing gas
    /// @notice Minimum amount of gas needed for a call via the forwarder
    uint256 public minProcessingGas;
    /// @notice Address of the Zbyte DPlat contract
    address public zbyteDPlat;
    /// @notice Amount of gas needed for a post execute to the DPlat
    uint256 public postExecGas;
    /// @notice Mapping of registered workers
    mapping (address => bool) public registeredWorkers;

    /// @notice Modifier to restrict a function to only be callable by registered workers.
    /// @dev The function using this modifier will only execute if the sender's address is a registered worker\
    ///  It will revert with a 'NotAWorker' error if the sender is not a registered worker.
    modifier onlyWorker() {
        if(!registeredWorkers[msg.sender]) revert NotAWorker(msg.sender);
        _;
    }

    /// @notice Sets the post execute processing gas
    /// @param postExecGas_ The new minimum processing gas value
    function setPostExecGas(uint256 postExecGas_) public onlyOwner {
        postExecGas = postExecGas_;
        emit ForwarderDplatPostExecGasSet(postExecGas_);
    }

    /// @notice Sets the minimum processing gas
    /// @param minProcessingGas_ The new minimum processing gas value
    function setMinProcessingGas(uint256 minProcessingGas_) public onlyOwner {
        minProcessingGas = minProcessingGas_;
        emit ForwarderDplatMinimumProcessingGasSet(minProcessingGas_);
    }

    /// @notice Sets the address of the Zbyte DPlat contract
    /// @param zbyteDPlat_ The address of the Zbyte DPlat contract
    function setZbyteDPlat(address zbyteDPlat_) public onlyOwner {
        if(zbyteDPlat_ == address(0)) revert ZeroAddress();
        zbyteDPlat = zbyteDPlat_;
        emit ForwarderDplatSet(zbyteDPlat_);
    }

    /// @notice Registers workers with the contract
    /// @param workers_ An array of worker addresses
    /// @param register_ An array of boolean values indicating registration status
    function registerWorkers(address[] calldata workers_,
                             bool[] calldata register_)
                             public onlyOwner {
        if(workers_.length != register_.length) revert ArraySizeMismatch(workers_.length, register_.length);

        for(uint256 i = 0; i < workers_.length; i++) {
            if(workers_[i] == address(0)) revert ZeroAddress();
            registeredWorkers[workers_[i]] = register_[i];
            emit ForwarderDplatWorkerRegistered(workers_[i], register_[i]);
        }
    }

    /// @notice Executes a forward request, ensuring that it is called by a registered worker and handling gas fees.
    /// @param req_ The forward request data containing the recipient, value, data, and other information.
    /// @param signature_ The signature for the forward request (if required).
    /// @return success A boolean indicating whether the execution was successful.
    /// @return returndata The return data from the executed contract.
    /// @dev This function facilitates call to a target contract while allowing the user to pay in DPLAT tokens\
    ///  The user would have received vERC20 necessary for the call execution.  An equivalent amount is charged in vERC20 from the user\
    ///  If the target contract accepts msg.value, equivalent of that is charged from the user during preExecute\
    ///  If preExecute collects more vERC20 than that is needed for the call, an event is emitted with the refund amount\
    ///  If the target contract sends any refund to the _msgSender(), the caller receives the refund directly
    ///  If the target contract call reverts, msg.value is not sent to the target and an event is emitted with the refund amount
    function zbyteExecute(ForwardRequest calldata req_,
                          bytes calldata signature_)
                          public
                          payable
                          onlyWorker
                          nonReentrant
                          returns(bool, bytes memory) {
        uint256 _startGas = gasleft();
        if(req_.value != msg.value) revert NotEnoughEtherSent(req_.value, msg.value);
        uint256 _preChargeEth = minProcessingGas * tx.gasprice + req_.value;

        address _payer = IZbyteDPlat(zbyteDPlat).preExecute(req_.to, req_.from, bytes4(req_.data[:4]), _preChargeEth);
        (bool _success, bytes memory _returndata) = MinimalForwarder.execute(req_, signature_);


        uint256 _gasConsumedEth = (postExecGas + _startGas - gasleft()) * tx.gasprice;
        IZbyteDPlat(zbyteDPlat).postExecute(_payer, _success, req_.value, _gasConsumedEth, _preChargeEth);
        emit ZbyteForwarderDPlatExecute(_success, _returndata);
        return(_success, _returndata);
    }

    /// @notice Allows the owner of the contract to withdraw the contract's Ether balance.
    /// @param receiver_ The address to which the Ether balance will be sent.
    function withdrawEth(address receiver_) public onlyOwner {
        (bool _sent, bytes memory _data) = receiver_.call{value: address(this).balance}("");
        (_data);
        if(!_sent) revert FailedToSendEther(receiver_, address(this).balance, _data);
    }
}