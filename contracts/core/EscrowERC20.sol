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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/ZbyteContext.sol";
import "../interface/relay/IRelayWrapper.sol";
import "../interface/core/IEscrowERC20.sol";
import "../interface/dplat/IZbytePriceFeeder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title The ERC20 Escrow contract
/// @dev DPLAT ERC20 escrow abstract contract
abstract contract EscrowERC20 is ZbyteContext, IEscrowERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // @notice Address to treasury. Holds the 'platform fee' tokens
    address public treasury;
    /// @notice Total vERC20 supply on all chains
    uint256 private _totalSupply;
    // @notice mapping of vERC20 amount for the chain
    mapping(uint256 => uint256) private _reserve;
    /// @notice mapping of the vERC20 contract address for the chain
    mapping(uint256 => address) public vERC20Addresses;
    /// @notice The underlying ERC20 token contract
    IERC20 public ulAsset;
    /// @notice Zbyte price feeder address.
    address zbytePriceFeeder;
    /// @notice Authorized workers
    mapping(address => bool) authorizedWorkers;
    /// @notice RelayWrapper contract address
    /// @dev Escrow can only use this trusted RelayWrapper to perform deposit/withdraw
    IRelayWrapper public relayWrapper;
    /// @notice nonce used for deposit/withdraw operations.  Incremented for every successful deposit or withdraw
    uint256 nonce;
    /// @notice enumeration of actions performed on this escrow
    enum Action {
        NONE,
        DEPOSIT,
        WITHDRAW
    }
    /// @notice Parameters of the deposit/withdraw operation.
    struct PendingAction {
        Action action;
        address nAddress;
        address rAddress;
        uint256 chainId;
        uint256 amount;
    }
    /// @notice mapping of current deposit/withdraw operations for which callback has not yet been received
    /// @dev action: EscrowERC20.Action that is being performed\
    ///   nAddress: Address from which ERC20 tokens are deposited (for Action.DEPOSIT) or tokens are received into (for Action.WITHDRAW)\
    ///   rAddress: Address to which vERC20 tokens are deposited (for Action.DEPOSIT) or tokens are received into (for Action.WITHDRAW)\
    ///   chainId: chain id of the remote chain\
    ///   amount: Amount of tokens that are deposited or withdrawn\
    /// @dev This is updated on successful deposit/withdraw and cleared when callback is received
    mapping(bytes32 => PendingAction) public pendingAction;

    /// @notice ZBYT ERC20 Escrow constructor
    /// @param forwarder_ Forwarder contact address
    /// @param asset_ Underlying ERC20 asset address
    constructor(address forwarder_, IERC20 asset_) {
        if (address(asset_) == address(0)) {
            revert ZeroAddress();
        }
        if(forwarder_ == address(0)) {
            revert ZeroAddress();
        }
        _setTrustedForwarder(forwarder_);
        ulAsset = asset_;
    }

    /// @notice receive function
    receive() external payable {
        revert CannotSendEther();
    }


    /**
    * @dev Modifier to ensure that the sender is an authorized worker.
    * @notice Reverts the transaction with an `UnAuthorized` error if the sender is not authorized.
    */
    modifier onlyAuthorized() {
        if (!authorizedWorkers[_msgSender()]) {
            revert UnAuthorized(_msgSender());
        }
        _;
    }

    /// @notice Modifier to enforce call only from valid relay contract
    modifier onlyRelay {
        if(!(relayWrapper.isValidRelay(block.chainid,_msgSender()))) {
            revert InvalidRelay(_msgSender());
        }
        _;
    }

    /// @notice Registers or unregisters a worker, allowing or denying access to specific functionality.
    /// @param worker_ The address of the worker to be registered or unregistered.
    /// @param register_ A boolean indicating whether to register (true) or unregister (false) the worker.
    function registerWorker(address worker_, bool register_) public onlyOwner {
        authorizedWorkers[worker_] = register_;
        emit WorkerRegistered(worker_, register_);
    }


    /// @notice Get the latest nonce 
    /// @dev nonce is incremented for every successful deposit or withdraw
    function getNonce() public view returns(uint256) {
        return nonce;
    }

    /// @notice Sets the address of the ZbytePriceFeeder contract.
    /// @dev This function allows updating the address of the ZbytePriceFeeder contract.
    /// @param zbytePriceFeederAddress_ The address of the ZbytePriceFeeder contract.
    function setZbytePriceFeederAddress(address zbytePriceFeederAddress_) public {
        zbytePriceFeeder = zbytePriceFeederAddress_;
        emit ZbytePriceFeederAddressSet(zbytePriceFeederAddress_);
    }

    /// @notice Set the treasury address
    /// @param treasury_ Treasury address
    function setTreasuryAddress(address treasury_) public onlyOwner {
        if(treasury_ == address(0)) {
            revert ZeroAddress();
        }
        address oldTreasury = treasury;
        treasury = treasury_;

        emit TreasuryAddressSet(oldTreasury,treasury);
    }

    /// @notice Set the address of vERC20 on a given chain
    /// @param verc20_ vERC20 contract address
    /// @param chain_ chain id of the chain where vERC2o contract resides
    /// @dev nonce is incremented for every successful deposit or withdraw
    function _setvERC20Address(address verc20_, uint256 chain_) internal {
        if (verc20_ == address(0)) {
            revert ZeroAddress();
        }
        if(chain_ == 0) {
            revert ZeroValue();
        }
        vERC20Addresses[chain_] = verc20_;

        emit vERC20AddressSet(verc20_,chain_);
    }

    /// @notice Set the address of core relay wrapper
    /// @param wrapper_ Core relay wrapper contract address
    function _setRelayWrapperAddress(address wrapper_) internal {
        if (wrapper_ == address(0)) {
            revert ZeroAddress();
        }
        relayWrapper = IRelayWrapper(wrapper_);

        emit RelayWrapperAddressSet(wrapper_);
    }

    /// @notice Return the amount of vERC20 currently available on all chains
    function totalSupplyAllChains() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Return the amount of vERC20 currently available on a given chain
    /// @param chain_ The id of the chain of interest
    function totalSupply(uint256 chain_) public view virtual override  returns (uint256) {
        return _reserve[chain_];
    }

    /// @notice Return the address of underlying ERC20 contract address
    function asset() external view virtual override returns (address) {
        return address(ulAsset);
    }

    /// @notice Record and update state on successful deposit/withdraw 
    /// @param action_ deposit or withdraw action
    /// @param amount_ amount of tokens deposited or withdrawn
    /// @param chain_ target chain id
    function _record(Action action_, uint256 amount_, uint256 chain_) internal {
        if (action_ == Action.DEPOSIT) {
            _totalSupply += amount_;
            _reserve[chain_] += amount_;
        } else if (action_ == Action.WITHDRAW){
            _totalSupply -= amount_;
            _reserve[chain_] -= amount_;
        }
     }

    /// @notice Deposit ERC20 tokens to obtain vERC20 on target chain
    /// @notice Deposit with ZbyteRelay is supported only via Zbyte Platform in case user deposits directly, it may result in loss of funds(Zbyte).
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param receiver_ Recipient address for vERC20
    /// @param amount_ Amount of ERC20 deposited
    function _deposit(uint256 relay_,
                      uint256 chain_,
                      address receiver_,
                      uint256 amount_)
                      internal
                      returns (bool result) {
        address verc20_ = vERC20Addresses[chain_];
        _beforeTokenDeposit(relay_, chain_, receiver_, amount_, verc20_);

        uint256 _gasCostForApproveAndDeposit = IZbytePriceFeeder(zbytePriceFeeder).getApproveAndDepositGasCostInZbyte(relay_, chain_);
        if(amount_ < _gasCostForApproveAndDeposit) revert InsufficientERC20ForDepositGas(amount_, _gasCostForApproveAndDeposit);


        IERC20(ulAsset).safeTransferFrom(_msgSender(), _getTrustedForwarder(), _gasCostForApproveAndDeposit);
        amount_ = amount_ - _gasCostForApproveAndDeposit;
        IERC20(ulAsset).safeTransferFrom(_msgSender(), address(this), amount_);

        bytes32 _ack = keccak256(abi.encodePacked(chain_,receiver_,amount_, nonce));
        nonce = nonce + 1;
        PendingAction memory pAction;
        pAction.action = Action.DEPOSIT;
        pAction.nAddress = _msgSender();
        pAction.rAddress = receiver_;
        pAction.chainId = chain_;
        pAction.amount = amount_;
        pendingAction[_ack] = pAction;
        result = relayWrapper.performCrossChainCall(relay_,
                                block.chainid,
                                chain_,
                                verc20_,
                                abi.encodeWithSignature("mint(address,uint256)",receiver_,amount_),
                                _ack,
                                address(this),
                                "");
        require(result, "_deposit: callRemote failed.");

        _afterTokenDeposit(relay_, chain_, receiver_, amount_, verc20_);

        emit ERC20Deposited(_msgSender(), receiver_, amount_, chain_,_ack);
        return result;
    }

    /// @notice Withdraw ERC20 tokens by depositing vERC20 on target chain
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param vERC20Depositor_ Address to deposit vERC20
    /// @param receiver_ Recipient address for ERC20
    /// @dev The paymaster_ should be a valid paymaster (e.g., forwarder). All vERC20 held by paymaster is destroyed and equal ERC20 is deposited
    function _withdraw(uint256 relay_,
                      uint256 chain_,
                      address vERC20Depositor_,
                      address receiver_)
                      internal
                      returns (bool result) {
        address verc20_ = vERC20Addresses[chain_];
        _beforeTokenWithdraw(relay_, chain_, vERC20Depositor_, receiver_, verc20_);

        bytes32 _ack = keccak256(abi.encodePacked(chain_,vERC20Depositor_,receiver_,nonce));
        nonce = nonce + 1;
        PendingAction memory pAction;
        pAction.action = Action.WITHDRAW;
        pAction.nAddress = receiver_;
        pAction.rAddress = vERC20Depositor_;
        pAction.chainId = chain_;
        pAction.amount = 0;
        pendingAction[_ack] = pAction;
        result = relayWrapper.performCrossChainCall(relay_,
                                block.chainid,
                                chain_,
                                verc20_,
                                abi.encodeWithSignature("destroy(address)",vERC20Depositor_),
                                _ack,
                                address(this),
                                "");

        require(result, "_withdraw: callRemote failed.");
        
        _afterTokenWithdraw(relay_, chain_, vERC20Depositor_, receiver_, verc20_);

        emit ERC20Withdrawn(_msgSender(), vERC20Depositor_, receiver_, chain_, _ack);
        return result;
    }

    /// @notice callback handler to handle acknowledgement for deposit/withdraw
    /// @param chain_ Target chain identifier
    /// @param ack_ Unique hash of the submitted deposit/withdraw request
    /// @param success_ true if the deposit/withdraw was successful on remote
    /// @param retval_ The amount of tokens that were deposited/withdrawn
    function _callbackHandler(uint256 chain_,
                            bytes32 ack_,
                            bool success_,
                            uint256  retval_)
        internal
        nonReentrant
        onlyRelay returns(uint256) {
        PendingAction storage _pAction = pendingAction[ack_];
        address _nAddress = _pAction.nAddress;
        uint256 _amount = _pAction.amount;
        uint256 _chainId = _pAction.chainId;

        if (_pAction.action == Action.DEPOSIT) {
            if ((chain_ != _chainId) || (_amount != retval_)) {
                revert InvalidCallbackMessage(_chainId, _amount, chain_, retval_);
            }
            if(success_) {
                _record(Action.DEPOSIT, _amount, _chainId);

                delete pendingAction[ack_];
                emit ERC20DepositConfirmed(ack_, success_,retval_);
            } else {
                IERC20(ulAsset).safeTransfer(_nAddress, _amount);
                delete pendingAction[ack_];
                emit ERC20DepositFailedAndRefunded(ack_, success_,retval_);
            }

        } else if (_pAction.action == Action.WITHDRAW && success_) {
            if (chain_ != _chainId) {
                revert InvalidCallbackMessage(_chainId, _amount, chain_, retval_);
            }
            IERC20(ulAsset).safeTransfer(_nAddress, retval_);
            _record(Action.WITHDRAW, _amount, _chainId);

            delete pendingAction[ack_];
            emit ERC20WithdrawConfirmed(ack_, success_,retval_);

        } else {
            revert InvalidCallbackAck(chain_,ack_, success_,retval_);
        }
        return 0;
    }

    /// @notice Hook called before token deposit
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param receiver_ Recipient address for vERC20
    /// @param amount_ Amount of ERC20 deposited
    /// @param verc20_ vERC20 contract address on target chain
    function _beforeTokenDeposit(uint256 relay_,
                      uint256 chain_,
                      address receiver_,
                      uint256 amount_,
                      address verc20_) internal  {}

    /// @notice Hook called after token deposit
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param receiver_ Recipient address for vERC20
    /// @param amount_ Amount of ERC20 deposited
    /// @param verc20_ vERC20 contract address on target chain
    function _afterTokenDeposit(uint256 relay_,
                      uint256 chain_,
                      address receiver_,
                      uint256 amount_,
                      address verc20_) internal  {}

    /// @notice Hook called before token withdraw
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param paymaster_ Paymaster address to deposit vERC20
    /// @param receiver_ Recipient address for ERC20
    /// @param verc20_ vERC20 contract address on target chain
    function _beforeTokenWithdraw(uint256 relay_,
                      uint256 chain_,
                      address paymaster_,
                      address receiver_,
                      address verc20_) internal  {}

    /// @notice Hook called after token withdraw
    /// @param relay_ Relay identifier that should be used for the crosschain call
    /// @param chain_ Target chain identifier
    /// @param paymaster_ Paymaster address to deposit vERC20
    /// @param receiver_ Recipient address for ERC20
    /// @param verc20_ vERC20 contract address on target chain
    function _afterTokenWithdraw(uint256 relay_,
                      uint256 chain_,
                      address paymaster_,
                      address receiver_,
                      address verc20_) internal  {}
}
