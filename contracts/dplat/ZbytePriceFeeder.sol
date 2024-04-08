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
import "../interface/dplat/IZbytePriceFeeder.sol";
import "../utils/ZbyteContext.sol";


/// @title ZbytePriceFeeder
/// @notice Implements the IZbytePriceFeeder interface and provides functionality to manage gas costs and price conversions.
contract ZbytePriceFeeder is IZbytePriceFeeder, ZbyteContext {
    /// @notice error (0xb3922495): Unauthorized caller.
    error UnAuthorized(address);

    /// @notice event (0x2ddb4d51): Worker is registered(true/false)
    event WorkerRegistered(address,bool);

    // Conversion factors
    uint256 public nativeEthEquivalentZbyteInGwei;
    uint256 public zbytePriceEquivalentInGwei;
    uint256 public burnRateInMill;
    /// @notice Authorized workers
    mapping(address => bool) public authorizedWorkers;

    /// @notice Constructor function to initialize the contract with a trusted forwarder address.
    /// @dev The trusted forwarder is used for meta transactions.
    /// @param forwarder_ The address of the trusted forwarder contract.
    constructor(address forwarder_) {
        _setTrustedForwarder(forwarder_);
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

    /// @notice Registers or unregisters a worker, allowing or denying access to specific functionality.
    /// @param worker_ The address of the worker to be registered or unregistered.
    /// @param register_ A boolean indicating whether to register (true) or unregister (false) the worker.
    function registerWorker(address worker_, bool register_) public onlyOwner {
        authorizedWorkers[worker_] = register_;
        emit WorkerRegistered(worker_, register_);
    }

    /// @notice Sets the equivalent Zbyte price in Gwei for native ETH.
    /// @dev Example:\
    /// Say, Native Eth Price = 1$\
    /// Zbyte Price = 2¢\
    /// Ratio(Native Eth Price / Zbyte Price) = 100 / 2\
    /// nativeEthEquivalentZbyteInGwei = Ratio * 10 ^ decimals() / Gwei\
    ///                                = 50 * 10 ^ 18 / 10 ^ 9 = 50,000,000,000\
    /// @param nativeEthEquivalentZbyteInGwei_ The equivalent Zbyte price in Gwei for native ETH.
    function setNativeEthEquivalentZbyteInGwei(uint256 nativeEthEquivalentZbyteInGwei_) public onlyAuthorized {
        nativeEthEquivalentZbyteInGwei = nativeEthEquivalentZbyteInGwei_;
        emit NativeEthEquivalentZbyteSet(nativeEthEquivalentZbyteInGwei_);
    }

    /// @notice Sets the Zbyte price in Gwei.
    /// @dev Example:\
    /// Say, Unit Price = 1$\
    /// Zbyte Price = 2¢\
    /// Ratio(Unit Price / Zbyte Price) = 100 / 2\
    /// zbytePriceInGwei_ = Ratio * 10 ^ decimals() / Gwei\
    ///                                = 50 * 10 ^ 18 / 10 ^ 9 = 50,000,000,000\
    /// @param zbytePriceInGwei_ The Zbyte price in Gwei.
    function setZbytePriceInGwei(uint256 zbytePriceInGwei_) public onlyAuthorized {
        zbytePriceEquivalentInGwei = zbytePriceInGwei_;
        emit ZbytePriceInGweiSet(zbytePriceInGwei_);
    }

    /// @notice Converts eth to equivalent Zbyte amount.
    /// @dev Example:\
    /// Say, Native Eth Price = 1$\
    /// Zbyte Price = 2¢\
    /// nativeEthEquivalentZbyteInGwei = 50,000,000,000 Gwei (i.e. 1 Native Eth = 50 Zbyte)\
    /// ethAmount_  = 1,000,000,000,000,000,000 Wei (1 Native Eth)\
    /// zbyteAmount = (1,000,000,000,000,000,000 * 50,000,000,000) / 1,000,000,000\
    ///             = 50,000,000,000,000,000,000 Wei (50 ZBYT)\
    /// @param ethAmount_ Amount of eth.
    /// @return Equivalent Amount of zbyte.
    function convertEthToEquivalentZbyte(uint256 ethAmount_) public view returns (uint256) {
        uint256 _zbyteAmount = (ethAmount_ * nativeEthEquivalentZbyteInGwei) / 10**9;
        return _zbyteAmount;
    }

    /// @notice Converts price in millionths to Zbyte amount.
    /// @dev Example:\
    /// Say, Unit Price = 1$\
    /// Zbyte Price = 2¢\
    /// So, zbytePriceEquivalentInGwei = 50,000,000,000 Gwei (i.e. 1 Unit = 50 Zbyte)\
    /// priceInMill_ = 20 Mill (i.e. (2 / 1000) Unit)\
    /// zbyteAmount = (20 * 50,000,000,000 * 1,000,000,000) / 1000\
    ///             = 1,000,000,000,000,000,000 Wei (1 ZBYT)\
    /// @param priceInMill_ Price in millionths.
    /// @return Equivalent Zbyte amount.
    function convertMillToZbyte(uint256 priceInMill_) public view returns (uint256) {
        return (priceInMill_ * zbytePriceEquivalentInGwei * 10**9) / 1000;
    }

    /// @notice DPlat fee in terms of Zbyte
    /// 1 Unit = 1000 Mill
    /// @return DPlat fee
    function getDPlatFeeInZbyte() public view returns(uint256) {
        return convertMillToZbyte(burnRateInMill);
    }

    /// @notice Sets the prices for the native ETH equivalent of Zbyte and the Zbyte price in Gwei.
    /// @dev This function is restricted to be called only by authorized users.
    /// @param nativeEthEquivalentZbyteInGwei_ The price of the native ETH equivalent of Zbyte in Gwei.
    /// @param zbytePriceInGwei_ The price of Zbyte in Gwei.
    function setPrices(uint256 nativeEthEquivalentZbyteInGwei_, uint256 zbytePriceInGwei_) external onlyAuthorized {
        setNativeEthEquivalentZbyteInGwei(nativeEthEquivalentZbyteInGwei_);
        setZbytePriceInGwei(zbytePriceInGwei_);
    }

    /// @notice Sets burn rate for invoke calls in mill
    /// 1 Unit = 1000 Mill
    /// @param burnRate_ burn rate in mill
    function setBurnRateInMill(uint256 burnRate_) public onlyOwner {
        burnRateInMill = burnRate_;
        emit BurnRateInMillSet(burnRate_);
    } 
}