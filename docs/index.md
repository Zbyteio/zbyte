# Solidity API

## EscrowERC20

_DPLAT ERC20 escrow abstract contract_

### vERC20Addresses

```solidity
mapping(uint256 => address) vERC20Addresses
```

mapping of the vERC20 contract address for the chain

### ulAsset

```solidity
contract IERC20 ulAsset
```

The underlying ERC20 token contract

### authorizedWorkers

```solidity
mapping(address => bool) authorizedWorkers
```

Authorized workers

### relayWrapper

```solidity
contract IRelayWrapper relayWrapper
```

RelayWrapper contract address

_Escrow can only use this trusted RelayWrapper to perform deposit/withdraw_

### nonce

```solidity
uint256 nonce
```

nonce used for deposit/withdraw operations.  Incremented for every successful deposit or withdraw

### Action

```solidity
enum Action {
  NONE,
  DEPOSIT,
  WITHDRAW,
  WITHDRAWROYALTY
}
```

### PendingAction

```solidity
struct PendingAction {
  enum EscrowERC20.Action action;
  address nAddress;
  address rAddress;
  uint256 chainId;
  uint256 amount;
}
```

### pendingAction

```solidity
mapping(bytes32 => struct EscrowERC20.PendingAction) pendingAction
```

mapping of current deposit/withdraw operations for which callback has not yet been received

_action: EscrowERC20.Action that is being performed\
  nAddress: Address from which ERC20 tokens are deposited (for Action.DEPOSIT) or tokens are received into (for Action.WITHDRAW)\
  rAddress: Address to which vERC20 tokens are deposited (for Action.DEPOSIT) or tokens are received into (for Action.WITHDRAW)\
  chainId: chain id of the remote chain\
  amount: Amount of tokens that are deposited or withdrawn\
This is updated on successful deposit/withdraw and cleared when callback is received_

### constructor

```solidity
constructor(address forwarder_, contract IERC20 asset_) internal
```

ZBYT ERC20 Escrow constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | Forwarder contact address |
| asset_ | contract IERC20 | Underlying ERC20 asset address |

### receive

```solidity
receive() external payable
```

receive function

### onlyAuthorized

```solidity
modifier onlyAuthorized()
```

Reverts the transaction with an `UnAuthorized` error if the sender is not authorized.

_Modifier to ensure that the sender is an authorized worker._

### onlyRelay

```solidity
modifier onlyRelay()
```

Modifier to enforce call only from valid relay contract

### registerWorker

```solidity
function registerWorker(address worker_, bool register_) public
```

Registers or unregisters a worker, allowing or denying access to specific functionality.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| worker_ | address | The address of the worker to be registered or unregistered. |
| register_ | bool | A boolean indicating whether to register (true) or unregister (false) the worker. |

### getNonce

```solidity
function getNonce() public view returns (uint256)
```

Get the latest nonce

_nonce is incremented for every successful deposit or withdraw_

### _setvERC20Address

```solidity
function _setvERC20Address(address verc20_, uint256 chain_) internal
```

Set the address of vERC20 on a given chain

_nonce is incremented for every successful deposit or withdraw_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| verc20_ | address | vERC20 contract address |
| chain_ | uint256 | chain id of the chain where vERC2o contract resides |

### _setRelayWrapperAddress

```solidity
function _setRelayWrapperAddress(address wrapper_) internal
```

Set the address of core relay wrapper

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| wrapper_ | address | Core relay wrapper contract address |

### totalSupplyAllChains

```solidity
function totalSupplyAllChains() public view virtual returns (uint256)
```

Return the amount of vERC20 currently available on all chains

### totalSupply

```solidity
function totalSupply(uint256 chain_) public view virtual returns (uint256)
```

Return the amount of vERC20 currently available on a given chain

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain_ | uint256 | The id of the chain of interest |

### asset

```solidity
function asset() external view virtual returns (address)
```

Return the address of underlying ERC20 contract address

### _record

```solidity
function _record(enum EscrowERC20.Action action_, uint256 amount_, uint256 chain_) internal
```

Record and update state on successful deposit/withdraw

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| action_ | enum EscrowERC20.Action | deposit or withdraw action |
| amount_ | uint256 | amount of tokens deposited or withdrawn |
| chain_ | uint256 | target chain id |

### _deposit

```solidity
function _deposit(uint256 relay_, uint256 chain_, address receiver_, uint256 cost_, uint256 amount_) internal returns (bool result)
```

Deposit ERC20 tokens to obtain vERC20 on target chain
Deposit with ZbyteRelay is supported only via Zbyte Platform in case user deposits directly, it may result in loss of funds(Zbyte).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| receiver_ | address | Recipient address for vERC20 |
| cost_ | uint256 | Cost of the operation |
| amount_ | uint256 | Amount of ERC20 deposited |

### _withdraw

```solidity
function _withdraw(uint256 relay_, uint256 chain_, address vERC20Depositor_, address receiver_) internal returns (bool result)
```

Withdraw ERC20 tokens by depositing vERC20 on target chain

_The paymaster_ should be a valid paymaster (e.g., forwarder). All vERC20 held by paymaster is destroyed and equal ERC20 is deposited_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| vERC20Depositor_ | address | Address to deposit vERC20 |
| receiver_ | address | Recipient address for ERC20 |

### _callbackHandler

```solidity
function _callbackHandler(uint256 chain_, bytes32 ack_, bool success_, uint256 retval_) internal returns (uint256)
```

callback handler to handle acknowledgement for deposit/withdraw

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain_ | uint256 | Target chain identifier |
| ack_ | bytes32 | Unique hash of the submitted deposit/withdraw request |
| success_ | bool | true if the deposit/withdraw was successful on remote |
| retval_ | uint256 | The amount of tokens that were deposited/withdrawn |

### _withdrawRoyalty

```solidity
function _withdrawRoyalty(uint256 relay_, uint256 chain_, address vERC20Depositor_, address receiver_, uint256 amount_) internal returns (bool result)
```

### _beforeTokenDeposit

```solidity
function _beforeTokenDeposit(uint256 relay_, uint256 chain_, address receiver_, uint256 amount_, address verc20_) internal
```

Hook called before token deposit

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| receiver_ | address | Recipient address for vERC20 |
| amount_ | uint256 | Amount of ERC20 deposited |
| verc20_ | address | vERC20 contract address on target chain |

### _afterTokenDeposit

```solidity
function _afterTokenDeposit(uint256 relay_, uint256 chain_, address receiver_, uint256 amount_, address verc20_) internal
```

Hook called after token deposit

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| receiver_ | address | Recipient address for vERC20 |
| amount_ | uint256 | Amount of ERC20 deposited |
| verc20_ | address | vERC20 contract address on target chain |

### _beforeTokenWithdraw

```solidity
function _beforeTokenWithdraw(uint256 relay_, uint256 chain_, address paymaster_, address receiver_, address verc20_) internal
```

Hook called before token withdraw

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| paymaster_ | address | Paymaster address to deposit vERC20 |
| receiver_ | address | Recipient address for ERC20 |
| verc20_ | address | vERC20 contract address on target chain |

### _afterTokenWithdraw

```solidity
function _afterTokenWithdraw(uint256 relay_, uint256 chain_, address paymaster_, address receiver_, address verc20_) internal
```

Hook called after token withdraw

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| paymaster_ | address | Paymaster address to deposit vERC20 |
| receiver_ | address | Recipient address for ERC20 |
| verc20_ | address | vERC20 contract address on target chain |

## ZbyteEscrow

### constructor

```solidity
constructor(address forwarder_, address zbyte_) public
```

### deposit

```solidity
function deposit(uint256 relay_, uint256 chain_, address receiver_, uint256 cost_, uint256 amount_) public returns (bool result)
```

Deposit ERC20 tokens to obtain vERC20 on target chain

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| receiver_ | address | Recipient address for vERC20 |
| cost_ | uint256 | Cost of the operation |
| amount_ | uint256 | Amount of ERC20 deposited |

### withdraw

```solidity
function withdraw(uint256 relay_, uint256 chain_, address vERC20Depositor_, address receiver_) public returns (bool result)
```

Withdraw ERC20 tokens by depositing vERC20 on target chain

_The paymaster_ should be a valid paymaster (e.g., forwarder). All vERC20 held by paymaster is destroyed and equal ERC20 is deposited_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| vERC20Depositor_ | address | Address to deposit vERC20 |
| receiver_ | address | Recipient address for ERC20 |

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 relay_, uint256 chain_, uint256 amount_) public returns (bool result)
```

Withdraw ERC20 tokens by depositing vERC20 on target chain

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relay_ | uint256 | Relay identifier that should be used for the crosschain call |
| chain_ | uint256 | Target chain identifier |
| amount_ | uint256 | Amount of tokens. |

### callbackHandler

```solidity
function callbackHandler(uint256 chain_, bytes32 ack_, bool success_, uint256 retval_) external returns (uint256)
```

callback handler to handle acknowledgement for deposit/withdraw

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain_ | uint256 | Target chain identifier |
| ack_ | bytes32 | Unique hash of the submitted deposit/withdraw request |
| success_ | bool | true if the deposit/withdraw was successful on remote |
| retval_ | uint256 | The amount of tokens that were deposited/withdrawn |

### setvERC20Address

```solidity
function setvERC20Address(address verc20_, uint256 chain_) public
```

Set the address of vERC20 on a given chain

_nonce is incremented for every successful deposit or withdraw_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| verc20_ | address | vERC20 contract address |
| chain_ | uint256 | chain id of the chain where vERC2o contract resides |

### setRelayWrapperAddress

```solidity
function setRelayWrapperAddress(address wrapper_) public
```

Set the address of core relay wrapper

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| wrapper_ | address | Core relay wrapper contract address |

### pause

```solidity
function pause() external
```

Pauses the contract (mint, transfer and burn operations are paused)

### unpause

```solidity
function unpause() external
```

Unpauses the paused contract

### _msgSender

```solidity
function _msgSender() internal view returns (address sender)
```

ERC2771 _msgSender override

### _msgData

```solidity
function _msgData() internal view returns (bytes)
```

ERC2771 _msgData override

## ZbyteForwarderCore

_The Zbyte core forwarder contract._

### ZeroAddress

```solidity
error ZeroAddress()
```

error (0xd92e233d): Address is address(0)

### ZbyteAddressSet

```solidity
event ZbyteAddressSet(address)
```

event (0xa6cc9cbb): DPLAT address is set

### ZbyteTokenForwarderAddressSet

```solidity
event ZbyteTokenForwarderAddressSet(address)
```

event (0x0a787863): Token forwarder address is set

### EscrowAddressSet

```solidity
event EscrowAddressSet(address)
```

event (0x14229a64) Escrow address is set

### zByteAddress

```solidity
address zByteAddress
```

DPLAT ERC20 contract address

### zbyteTokenForwarder

```solidity
contract MinimalForwarder zbyteTokenForwarder
```

Forwarder of ERC20 token contract

### escrowAddress

```solidity
address escrowAddress
```

Escrow contract address

### setZbyteAddress

```solidity
function setZbyteAddress(address zbyte_) public
```

Set DPLAT ERC20 address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| zbyte_ | address | DPLAT ERC20 contact address |

### setZbyteTokenForwarderAddress

```solidity
function setZbyteTokenForwarderAddress(address forwarder_) public
```

Set DPLAT ERC20 Forwarder address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | DPLAT ERC20 forwarder contact address |

### setEscrowAddress

```solidity
function setEscrowAddress(address escrow_) public
```

Set Zbyte Escrow address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| escrow_ | address | Zbyte Escrow contract address |

### approveAndDeposit

```solidity
function approveAndDeposit(struct MinimalForwarder.ForwardRequest reqApprove_, bytes signatureApprove_, struct MinimalForwarder.ForwardRequest reqDeposit_, bytes signatureDeposit_) public payable returns (bool success)
```

Perform approve and depost of Zbyte in single call

_Allows gasless approve+deposit of DPLAT token to be used at https://dplat.zbyte.io_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| reqApprove_ | struct MinimalForwarder.ForwardRequest | ForwardRequest for the approve call |
| signatureApprove_ | bytes | Signature of the approve call params |
| reqDeposit_ | struct MinimalForwarder.ForwardRequest | ForwardRequest for the deposit call |
| signatureDeposit_ | bytes | Signature of the deposit call params |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| success | bool | returns true of approve and deposit are successful |

## LibDPlatBase

Library for DPlat base storage and functions

_Library for DPlat base storage and functions_

### PreExecStates

```solidity
struct PreExecStates {
  bytes4 enterprise;
  address enterprisePolicy;
  uint256 enterpriseEligibilityGas;
  address user;
  address dapp;
  bytes4 functionSig;
}
```

### DiamondStorage

```solidity
struct DiamondStorage {
  struct LibDPlatBase.PreExecStates preExecuteStates;
  address zbyteVToken;
  address zbytePriceFeeder;
}
```

### diamondStorage

```solidity
function diamondStorage() internal pure returns (struct LibDPlatBase.DiamondStorage ds)
```

Retrieves the DiamondStorage struct for the library.

_zbyteVToken: The address of the ZbyteVToken\
 zbyteValueInNativeEthGwei: The value of Zbyte in native Ether (in Gwei)\
 zbyteBurnFactor: Burn factor, represents the percent of gas used that will be 'burnt'_

### _getZbyteVToken

```solidity
function _getZbyteVToken() internal view returns (address)
```

Gets the ZbyteVToken address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the ZbyteVToken. |

### _getZbytePriceFeeder

```solidity
function _getZbytePriceFeeder() internal view returns (address)
```

_Retrieves the address of the Zbyte price feeder from DiamondStorage._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the Zbyte price feeder. |

### _setPreExecStates

```solidity
function _setPreExecStates(bytes4 enterprise_, uint256 enterpriseEligibilityGas_, address enterprisePolicy_, address user_, address dapp_, bytes4 functionSig_) internal
```

_Sets the pre-execution states with the specified enterprise identifier._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The enterprise identifier to be set in the pre-execution states. |
| enterpriseEligibilityGas_ | uint256 |  |
| enterprisePolicy_ | address |  |
| user_ | address |  |
| dapp_ | address |  |
| functionSig_ | bytes4 |  |

### _getPreExecStates

```solidity
function _getPreExecStates() internal view returns (struct LibDPlatBase.PreExecStates)
```

_Retrieves the pre-execution states from DiamondStorage._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LibDPlatBase.PreExecStates | The pre-execution states stored in DiamondStorage. |

## LibDPlatRegistration

Library for DPlat registration storage and functions

_Library for DPlat registration storage and functions_

### ZbyteDPlatEnterpriseLimitSet

```solidity
event ZbyteDPlatEnterpriseLimitSet(bytes4, uint256, uint256)
```

event (0x75ee1f8e): Zbyte DPlat enterprise limit is set.

### DiamondStorage

```solidity
struct DiamondStorage {
  mapping(bytes4 => address) registeredEnterprises;
  mapping(bytes4 => address) registeredEnterprisePolicy;
  mapping(address => bytes4) registeredDapps;
  mapping(address => bytes4) registeredEnterpriseUsers;
  mapping(bytes4 => uint256) enterpriseLimit;
}
```

### diamondStorage

```solidity
function diamondStorage() internal pure returns (struct LibDPlatRegistration.DiamondStorage ds)
```

Retrieves the DiamondStorage struct for the library.

_registeredEnterprises: Mapping of registered enterprises by bytes4 ID\
 registeredEnterprisePolicy: Mapping of enterprise policies by bytes4 ID\
 registeredDapps: Mapping of registered Dapps by address\
 registeredEnterpriseUsers: Mapping of registered enterprise users by address\
 enterpriseLimit: Mapping of enterprise limits by bytes4 ID_

### _getEnterpriseLimit

```solidity
function _getEnterpriseLimit(bytes4 enterprise_) internal view returns (uint256)
```

Gets the enterprise limit for a given enterprise ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The enterprise ID. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The enterprise limit. |

### _setEntepriseLimit

```solidity
function _setEntepriseLimit(bytes4 enterprise_, uint256 amount_) internal
```

Sets the enterprise limit for a given enterprise ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The enterprise ID. |
| amount_ | uint256 | The limit amount to set. |

### _doesEnterpriseHavePolicy

```solidity
function _doesEnterpriseHavePolicy(bytes4 enterprise_) internal view returns (address)
```

Checks if an enterprise has a registered policy and retrieves the policy address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The enterprise ID. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Enterprise payment policy address. |

### isProviderRegistered

```solidity
function isProviderRegistered(address provider_) internal view returns (bool)
```

Checks if the given provider is registered

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| provider_ | address | The provider address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool indicating if the provider is registered |

### isProviderAgentRegistered

```solidity
function isProviderAgentRegistered(address agent_) internal view returns (address)
```

Checks if the given agent is registered

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| agent_ | address | The agent address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | returns the address of provider if registered, or address(0) |

### isEnterpriseRegistered

```solidity
function isEnterpriseRegistered(bytes4 enterprise_) internal view returns (address)
```

Checks if the given enterprise is registered

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The enterprise bytes4 ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | returns the address of provider if registered, or address(0) |

### isEnterpriseUserRegistered

```solidity
function isEnterpriseUserRegistered(address user_) internal view returns (bytes4)
```

Checks if the given user is registered with an enterprise

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user_ | address | The user address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | returns the address of provider if registered, or address(0) |

### isEnterpriseDappRegistered

```solidity
function isEnterpriseDappRegistered(address dapp_) internal view returns (bytes4)
```

Checks if the given dapp (contract) is registered with an enterprise

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dapp_ | address | The contract address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | returns the address of provider if registered, or address(0) |

## LibDPlatProvider

Library for DPlat provider storage and functions

_Library for DPlat provider storage and functions_

### DiamondStorage

```solidity
struct DiamondStorage {
  mapping(address => bool) registeredProviders;
  mapping(address => address) registeredProviderAgent;
}
```

### diamondStorage

```solidity
function diamondStorage() internal pure returns (struct LibDPlatProvider.DiamondStorage ds)
```

Retrieves the DiamondStorage struct for the library.

_registeredProviders: Mapping of registered providers by address\
 registeredProviderAgent: Mapping of registered provider agents by address_

## ZbyteDPlatBaseFacet

_DPlat Base Facet contract_

### ZbyteVTokenAddressSet

```solidity
event ZbyteVTokenAddressSet(address)
```

event (0x10e1dc22): VZbyte token address is set.

### ZbyteValueInNativeEthGweiSet

```solidity
event ZbyteValueInNativeEthGweiSet(uint256)
```

event (0xa0e61546): Zbyte token value in terms of native eth is set.

### ZbyteBurnFactorSet

```solidity
event ZbyteBurnFactorSet(uint256)
```

event (0xd7a7cf8c): Zbyte burn factor is set.

### ZbytePriceFeederSet

```solidity
event ZbytePriceFeederSet(address)
```

event (0xe603ec36): Zbyte price feeder is set.

### setZbyteVToken

```solidity
function setZbyteVToken(address zbyteVToken_) public
```

Sets the address of the ZbyteVToken.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| zbyteVToken_ | address | The address of the ZbyteVToken. |

### setZbytePriceFeeder

```solidity
function setZbytePriceFeeder(address zbytePriceFeeder_) public
```

Sets the Zbyte Price Feeder address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| zbytePriceFeeder_ | address | Zbyte Price Feeder address. |

### getZbyteVToken

```solidity
function getZbyteVToken() public view returns (address)
```

Gets the address of the ZbyteVToken.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the ZbyteVToken. |

### getZbytePriceFeeder

```solidity
function getZbytePriceFeeder() public view returns (address)
```

## ZbyteDPlatPaymentFacet

### PreExecFees

```solidity
event PreExecFees(address, bytes4, uint256, uint256, uint256)
```

events
Event(0x0f1db6a3) Address of the payer, enterprise hash, DPlat, Infra and Royalty Fee

### PostExecFees

```solidity
event PostExecFees(address, uint256, uint256, uint256)
```

Event(0x5ccdbb95) Address of the payer, Pre Exec charge, Post Exec Charge, Refund if neccessary

### GetRoyaltyFeeInZbyteFailed

```solidity
error GetRoyaltyFeeInZbyteFailed(bytes)
```

error
Error(0x91acbad9) Error details for getRoyaltyFee failure.

### UnusualGasUsageForEnterprisePolicy

```solidity
error UnusualGasUsageForEnterprisePolicy(uint256, uint256)
```

Error(0x72b10f2e) Error unusal gas usage for enterprise policy updation.

### getPayer

```solidity
function getPayer(address user_, address dapp_, bytes4 functionSig_, uint256 amount_) public view returns (bytes4, uint256, address)
```

Determines the payer for a transaction.
In the absence of an enteprise policy, if a dapp or user is registered with ent,
ent will pay for the call, as long as it has balance

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user_ | address | The user's address. |
| dapp_ | address | The Dapp's address. |
| functionSig_ | bytes4 | The function signature (bytes4). |
| amount_ | uint256 | The transaction amount. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | The payer's address. |
| [1] | uint256 |  |
| [2] | address |  |

### preExecute

```solidity
function preExecute(address dapp_, address user_, bytes4 functionSig_, uint256 ethChargeAmount_) public returns (address)
```

Pre Execution (Finds the payer and charges in ZbyteVToken)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dapp_ | address | The Dapp's address. |
| user_ | address | The user's address. |
| functionSig_ | bytes4 | The function signature (bytes4). |
| ethChargeAmount_ | uint256 | The Ether amount to charge. |

### postExecute

```solidity
function postExecute(address payer_, bool executeResult_, uint256 reqValue_, uint256 gasConsumedEth_, uint256 preChargeEth_) public
```

_Executes a transaction and handles Zbyte-related operations._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payer_ | address | The address of the payer initiating the execution. |
| executeResult_ | bool | A boolean indicating the success of the execution. |
| reqValue_ | uint256 | The amount of Ether sent with the execution request. |
| gasConsumedEth_ | uint256 | The amount of Ether consumed for gas during execution. |
| preChargeEth_ | uint256 | The amount of Ether charged before execution. This function can only be called by the `onlyForwarder` modifier. |

## ZbyteDPlatRegistrationFacet

Zbyte DPlat Registration Facet

_Zbyte DPlat Registration Facet_

### ZbyteDPlatProviderRegistred

```solidity
event ZbyteDPlatProviderRegistred(address, bool)
```

events
event (0x2a3043c9): Zbyte DPlat provider is registered.

### ZbyteDPlatProviderAgentRegistered

```solidity
event ZbyteDPlatProviderAgentRegistered(address, address)
```

event (0xb0c62993): Zbyte DPlat provider agent is registered.

### ZbyteDPlatEnterpriseRegistered

```solidity
event ZbyteDPlatEnterpriseRegistered(bytes4, address)
```

event (0xa98ff618): Zbyte DPlat enterprise is registered.

### ZbyteDPlatEnterpriseUserRegistered

```solidity
event ZbyteDPlatEnterpriseUserRegistered(address, bytes4)
```

event (0x83439d26): Zbyte DPlat enterprise user is registered.

### ZbyteDPlatDappRegistered

```solidity
event ZbyteDPlatDappRegistered(address, bytes4)
```

event (0x822d049d): Zbyte DPlat dapp is registered.

### ZbyteDPlatEnterpriseLimitSet

```solidity
event ZbyteDPlatEnterpriseLimitSet(bytes4, uint256, uint256)
```

event (0x75ee1f8e): Zbyte DPlat enterprise limit is set.

### ProviderAlreadyRegistered

```solidity
error ProviderAlreadyRegistered(address)
```

errors
error (0x74f7822a): Provider already registered.

### ProviderNotRegistered

```solidity
error ProviderNotRegistered(address)
```

error (0x232cb27a): Provider not registered.

### InvalidEnterprise

```solidity
error InvalidEnterprise(bytes4)
```

error (0x128c088b): Invalid enterprise hash.

### ProviderAgentAlreadyRegistered

```solidity
error ProviderAgentAlreadyRegistered(address)
```

error (0xe751ad65): Provider Agent is already registered.

### ProviderAgentNotRegistered

```solidity
error ProviderAgentNotRegistered(address)
```

error (0xd0141a6a): Not a registered provider agent.

### InvalidProvider

```solidity
error InvalidProvider(address)
```

error (0x96271599): Invalid provider.

### EnterpriseAlreadyRegistered

```solidity
error EnterpriseAlreadyRegistered(bytes4)
```

error (0x6d998cea): Enterprise is already registered.

### EnterpriseNotRegistered

```solidity
error EnterpriseNotRegistered(bytes4)
```

error (0xbd825961): Enterprise is not registered.

### NotARegisteredProvider

```solidity
error NotARegisteredProvider(address)
```

error (0xca61871b): Not a registered provider.

### EnterpriseUserAlreadyRegistered

```solidity
error EnterpriseUserAlreadyRegistered(address)
```

error (0x43469070): Enterprise user is already registered.

### EnterpriseUserNotRegistered

```solidity
error EnterpriseUserNotRegistered(address)
```

error (0x1b7bfcf8): Enterprise user is not registered.

### EnterpriseDappAlreadyRegistered

```solidity
error EnterpriseDappAlreadyRegistered(address)
```

error (0xbcb8afa4): Enterprise dapp is already registered.

### EnterpriseDappNotRegistered

```solidity
error EnterpriseDappNotRegistered(address)
```

error (0x31b254a2): Enterprise dapp is not registered.

### _setRegisteredProvider

```solidity
function _setRegisteredProvider(address provider_, bool set_) internal
```

Internal function to set the registration status of a provider.

_This function is used internally to manage the registration status of providers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| provider_ | address | The address of the provider whose registration status will be set. |
| set_ | bool | A boolean indicating whether to set the provider as registered or not. |

### _setRegisteredProviderAgent

```solidity
function _setRegisteredProviderAgent(address agent_, address provider_) internal
```

Internal function to set the registration of a provider agent.

_This function is used internally to manage the registration of provider agents._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| agent_ | address | The address of the agent whose provider registration will be set. |
| provider_ | address | The address of the provider associated with the agent. |

### _setRegisteredEnterprise

```solidity
function _setRegisteredEnterprise(bytes4 enterprise_, address provider_) internal
```

Internal function to set the registration status of an enterprise.

_This function is used internally to manage the registration status of enterprises._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The identifier of the enterprise whose registration status will be set. |
| provider_ | address | The address of the provider associated with the enterprise. |

### _setRegisteredEnterpriseUser

```solidity
function _setRegisteredEnterpriseUser(address user_, bytes4 enterprise_) internal
```

Internal function to set the registration status of an enterprise user.

_This function is used internally to manage the registration status of enterprise users._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user_ | address | The address of the user whose enterprise registration will be set. |
| enterprise_ | bytes4 | The identifier of the enterprise associated with the user. |

### _setRegisteredEnterpriseDapp

```solidity
function _setRegisteredEnterpriseDapp(address dapp_, bytes4 enterprise_) internal
```

Internal function to set the registration status of an enterprise Dapp.

_This function is used internally to manage the registration status of enterprise Dapps._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dapp_ | address | The address of the Dapp whose enterprise registration will be set. |
| enterprise_ | bytes4 | The identifier of the enterprise associated with the Dapp. |

### isProviderRegistered

```solidity
function isProviderRegistered(address provider_) public view returns (bool)
```

Checks if a provider is registered.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| provider_ | address | The address of the provider to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean indicating whether the provider is registered. |

### isProviderAgentRegistered

```solidity
function isProviderAgentRegistered(address agent_) public view returns (address)
```

Checks if a provider agent is registered and returns the associated provider's address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| agent_ | address | The address of the provider agent to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the associated registered provider. |

### isEnterpriseRegistered

```solidity
function isEnterpriseRegistered(bytes4 enterprise_) public view returns (address)
```

Checks if an enterprise is registered and returns the associated provider's address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The identifier of the enterprise to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the associated registered provider. |

### isEnterpriseUserRegistered

```solidity
function isEnterpriseUserRegistered(address user_) public view returns (bytes4)
```

Checks if an enterprise user is registered and returns the associated enterprise identifier.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user_ | address | The address of the user to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | The identifier of the associated registered enterprise. |

### isEnterpriseDappRegistered

```solidity
function isEnterpriseDappRegistered(address dapp_) public view returns (bytes4)
```

Checks if an enterprise Dapp is registered and returns the associated enterprise identifier.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dapp_ | address | The address of the Dapp to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | The identifier of the associated registered enterprise. |

### registerProvider

```solidity
function registerProvider() public
```

Registers a provider.

_Relation between provider, agent, enterprise, users and dapps is as follows:

zbyte\
____(1) <--------> (n) provider\
____________________________(1) <--------> (n) agent\
____________________________(1) <--------> (n) enterprise\
________________________________________________________(1) <--------> (n) user\
________________________________________________________(1) <--------> (n) dapp

  For an enterprise usecase, an enterprise can allow users to invoke registered dapps.\
  Users can invoke the contract functions without any need to hold crypto assets.\
  L1 needed for the call is given by the authorized workers and providers compensate them in vERC20.\
\
  For opensource usecase,\
  Users can invoke the contract functions without any need to hold L1 assets.\
  L1 needed for the call is given by the authorized workers and the users compensate them in vERC20\
\
  NOTE: When one of the components (provider, enterprise, agent, user or dapp) is deregistered,\
   all the other components registered under it remain registered.\
   So, if the component is registered again, the entire subtree becomes active again_

### deregisterProvider

```solidity
function deregisterProvider() public
```

Deregisters a provider.

### registerProviderAgent

```solidity
function registerProviderAgent(address agent_) public
```

Registers a provider agent.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| agent_ | address | The address of the provider agent to register. |

### deRegisterProviderAgent

```solidity
function deRegisterProviderAgent(address agent_) public
```

Deregisters a provider agent.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| agent_ | address | The address of the provider agent to deregister. |

### registerEnterprise

```solidity
function registerEnterprise(bytes4 enterprise_) public
```

Registers an enterprise.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The bytes4 identifier of the enterprise to register. |

### deregisterEnterprise

```solidity
function deregisterEnterprise(bytes4 enterprise_) public
```

Deregisters an enterprise.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The bytes4 identifier of the enterprise to deregister. |

### registerEnterpriseUser

```solidity
function registerEnterpriseUser(address user_, bytes4 enterprise_) public
```

Registers an enterprise user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user_ | address | The address of the user to register. |
| enterprise_ | bytes4 | The bytes4 identifier of the enterprise. |

### deregisterEnterpriseUser

```solidity
function deregisterEnterpriseUser(address user_) public
```

Deregisters an enterprise user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user_ | address | The address of the user to deregister. |

### registerDapp

```solidity
function registerDapp(address dapp_, bytes4 enterprise_) public
```

Registers a Dapp for an enterprise.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dapp_ | address | The address of the Dapp to register. |
| enterprise_ | bytes4 | The bytes4 identifier of the enterprise. |

### deregisterDapp

```solidity
function deregisterDapp(address dapp_) public
```

Deregisters a Dapp for an enterprise.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dapp_ | address | The address of the Dapp to deregister. |

### setEnterpriseLimit

```solidity
function setEnterpriseLimit(bytes4 enterprise_, uint256 amount_) public
```

Sets the enterprise limit for a specific enterprise.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| enterprise_ | bytes4 | The bytes4 identifier of the enterprise. |
| amount_ | uint256 | The new limit amount. |

### getEnterpriseLimit

```solidity
function getEnterpriseLimit(bytes4 enterprise_) public view returns (uint256)
```

## LibDPlatRoyalty

### DiamondStorage

```solidity
struct DiamondStorage {
  mapping(address => uint256) royaltyDapp;
}
```

### diamondStorage

```solidity
function diamondStorage() internal pure returns (struct LibDPlatRoyalty.DiamondStorage ds)
```

Retrieves the DiamondStorage struct for the library.

## ZbyteDPlatRoyaltyFacet

_This contract extends ZbyteContextDiamond and provides functionality related to royalty fees in Zbyte._

### getRoyaltyFeeInZbyte

```solidity
function getRoyaltyFeeInZbyte(address dapp_, address user_, bytes4 functionSig_, address payer_, uint256 zbyteCharge_) external view returns (uint256, address, address)
```

_Retrieves the royalty fee in Zbyte for a specific DApp function._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dapp_ | address | The address of the DApp. |
| user_ | address | The address of the user involved in the DApp function. |
| functionSig_ | bytes4 | The function signature of the DApp function. |
| payer_ | address | The address of the entity paying the royalty fee. |
| zbyteCharge_ | uint256 | The Zbyte charge associated with the DApp function. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The royalty fee in Zbyte. |
| [1] | address | address The address of the payer. |
| [2] | address |  |

## ZbyteForwarderDPlat

### ForwarderDplatSet

```solidity
event ForwarderDplatSet(address)
```

events
event (0xeae099e1): Forwarder address is set.

### ForwarderDplatMinimumProcessingGasSet

```solidity
event ForwarderDplatMinimumProcessingGasSet(uint256)
```

event (0x6342abcf): Forwarder minimum processing gas is set.

### ForwarderDplatWorkerRegistered

```solidity
event ForwarderDplatWorkerRegistered(address, bool)
```

event (0xe1554bda): Forwarder worker is registered.

### RefundEth

```solidity
event RefundEth(address, uint256)
```

event (0xe5cac075): Refund Eth to payer.

### ZbyteForwarderDPlatExecute

```solidity
event ZbyteForwarderDPlatExecute(bool, bytes)
```

event (0x5c3206c6): Execute result and return data

### ForwarderDplatPostExecGasSet

```solidity
event ForwarderDplatPostExecGasSet(uint256)
```

event (0x1f32728a): Forwarder post exec gas is set.

### ZeroAddress

```solidity
error ZeroAddress()
```

errors
error (0xd92e233d): Address is zero.

### ArraySizeMismatch

```solidity
error ArraySizeMismatch(uint256, uint256)
```

error (0xfb3dd446): Array sizes don't match.

### NotEnoughEtherSent

```solidity
error NotEnoughEtherSent(uint256, uint256)
```

error (0xf9309a09): Not enough ether sent the function.

### FailedToSendEther

```solidity
error FailedToSendEther(address, uint256, bytes)
```

error (0xb7da4a55): Failed to send ether.

### NotAWorker

```solidity
error NotAWorker(address)
```

error (0x9059e055): Not a worker.

### minProcessingGas

```solidity
uint256 minProcessingGas
```

Minimum amount of gas needed for a call via the forwarder

### zbyteDPlat

```solidity
address zbyteDPlat
```

Address of the Zbyte DPlat contract

### postExecGas

```solidity
uint256 postExecGas
```

Amount of gas needed for a post execute to the DPlat

### registeredWorkers

```solidity
mapping(address => bool) registeredWorkers
```

Mapping of registered workers

### onlyWorker

```solidity
modifier onlyWorker()
```

Modifier to restrict a function to only be callable by registered workers.

_The function using this modifier will only execute if the sender's address is a registered worker\
 It will revert with a 'NotAWorker' error if the sender is not a registered worker._

### setPostExecGas

```solidity
function setPostExecGas(uint256 postExecGas_) public
```

Sets the post execute processing gas

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| postExecGas_ | uint256 | The new minimum processing gas value |

### setMinProcessingGas

```solidity
function setMinProcessingGas(uint256 minProcessingGas_) public
```

Sets the minimum processing gas

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minProcessingGas_ | uint256 | The new minimum processing gas value |

### setZbyteDPlat

```solidity
function setZbyteDPlat(address zbyteDPlat_) public
```

Sets the address of the Zbyte DPlat contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| zbyteDPlat_ | address | The address of the Zbyte DPlat contract |

### registerWorkers

```solidity
function registerWorkers(address[] workers_, bool[] register_) public
```

Registers workers with the contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| workers_ | address[] | An array of worker addresses |
| register_ | bool[] | An array of boolean values indicating registration status |

### zbyteExecute

```solidity
function zbyteExecute(struct MinimalForwarder.ForwardRequest req_, bytes signature_) public payable returns (bool, bytes)
```

Executes a forward request, ensuring that it is called by a registered worker and handling gas fees.

_This function facilitates call to a target contract while allowing the user to pay in DPLAT tokens\
 The user would have received vERC20 necessary for the call execution.  An equivalent amount is charged in vERC20 from the user\
 If the target contract accepts msg.value, equivalent of that is charged from the user during preExecute\
 If preExecute collects more vERC20 than that is needed for the call, an event is emitted with the refund amount\
 If the target contract sends any refund to the _msgSender(), the caller receives the refund directly
 If the target contract call reverts, msg.value is not sent to the target and an event is emitted with the refund amount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| req_ | struct MinimalForwarder.ForwardRequest | The forward request data containing the recipient, value, data, and other information. |
| signature_ | bytes | The signature for the forward request (if required). |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | success A boolean indicating whether the execution was successful. |
| [1] | bytes | returndata The return data from the executed contract. |

### withdrawEth

```solidity
function withdrawEth(address receiver_) public
```

Allows the owner of the contract to withdraw the contract's Ether balance.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| receiver_ | address | The address to which the Ether balance will be sent. |

## ZbytePriceFeeder

Implements the IZbytePriceFeeder interface and provides functionality to manage gas costs and price conversions.

### UnAuthorized

```solidity
error UnAuthorized(address)
```

error (0xb3922495): Unauthorized caller.

### WorkerRegistered

```solidity
event WorkerRegistered(address, bool)
```

event (0x2ddb4d51): Worker is registered(true/false)

### nativeEthEquivalentZbyteInGwei

```solidity
uint256 nativeEthEquivalentZbyteInGwei
```

### zbytePriceEquivalentInGwei

```solidity
uint256 zbytePriceEquivalentInGwei
```

### burnRateInMill

```solidity
uint256 burnRateInMill
```

### authorizedWorkers

```solidity
mapping(address => bool) authorizedWorkers
```

Authorized workers

### constructor

```solidity
constructor(address forwarder_) public
```

Constructor function to initialize the contract with a trusted forwarder address.

_The trusted forwarder is used for meta transactions._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | The address of the trusted forwarder contract. |

### onlyAuthorized

```solidity
modifier onlyAuthorized()
```

Reverts the transaction with an `UnAuthorized` error if the sender is not authorized.

_Modifier to ensure that the sender is an authorized worker._

### registerWorker

```solidity
function registerWorker(address worker_, bool register_) public
```

Registers or unregisters a worker, allowing or denying access to specific functionality.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| worker_ | address | The address of the worker to be registered or unregistered. |
| register_ | bool | A boolean indicating whether to register (true) or unregister (false) the worker. |

### setNativeEthEquivalentZbyteInGwei

```solidity
function setNativeEthEquivalentZbyteInGwei(uint256 nativeEthEquivalentZbyteInGwei_) public
```

Sets the equivalent Zbyte price in Gwei for native ETH.

_Example:\
Say, Native Eth Price = 1$\
Zbyte Price = 2¢\
Ratio(Native Eth Price / Zbyte Price) = 100 / 2\
nativeEthEquivalentZbyteInGwei = Ratio * 10 ^ decimals() / Gwei\
                               = 50 * 10 ^ 18 / 10 ^ 9 = 50,000,000,000\_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nativeEthEquivalentZbyteInGwei_ | uint256 | The equivalent Zbyte price in Gwei for native ETH. |

### setZbytePriceInGwei

```solidity
function setZbytePriceInGwei(uint256 zbytePriceInGwei_) public
```

Sets the Zbyte price in Gwei.

_Example:\
Say, Unit Price = 1$\
Zbyte Price = 2¢\
Ratio(Unit Price / Zbyte Price) = 100 / 2\
zbytePriceInGwei_ = Ratio * 10 ^ decimals() / Gwei\
                               = 50 * 10 ^ 18 / 10 ^ 9 = 50,000,000,000\_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| zbytePriceInGwei_ | uint256 | The Zbyte price in Gwei. |

### convertEthToEquivalentZbyte

```solidity
function convertEthToEquivalentZbyte(uint256 ethAmount_) public view returns (uint256)
```

Converts eth to equivalent Zbyte amount.

_Example:\
Say, Native Eth Price = 1$\
Zbyte Price = 2¢\
nativeEthEquivalentZbyteInGwei = 50,000,000,000 Gwei (i.e. 1 Native Eth = 50 Zbyte)\
ethAmount_  = 1,000,000,000,000,000,000 Wei (1 Native Eth)\
zbyteAmount = (1,000,000,000,000,000,000 * 50,000,000,000) / 1,000,000,000\
            = 50,000,000,000,000,000,000 Wei (50 ZBYT)\_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ethAmount_ | uint256 | Amount of eth. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Equivalent Amount of zbyte. |

### convertMillToZbyte

```solidity
function convertMillToZbyte(uint256 priceInMill_) public view returns (uint256)
```

Converts price in millionths to Zbyte amount.

_Example:\
Say, Unit Price = 1$\
Zbyte Price = 2¢\
So, zbytePriceEquivalentInGwei = 50,000,000,000 Gwei (i.e. 1 Unit = 50 Zbyte)\
priceInMill_ = 20 Mill (i.e. (2 / 1000) Unit)\
zbyteAmount = (20 * 50,000,000,000 * 1,000,000,000) / 1000\
            = 1,000,000,000,000,000,000 Wei (1 ZBYT)\_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| priceInMill_ | uint256 | Price in millionths. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Equivalent Zbyte amount. |

### getDPlatFeeInZbyte

```solidity
function getDPlatFeeInZbyte() public view returns (uint256)
```

DPlat fee in terms of Zbyte
1 Unit = 1000 Mill

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | DPlat fee |

### setPrices

```solidity
function setPrices(uint256 nativeEthEquivalentZbyteInGwei_, uint256 zbytePriceInGwei_) external
```

Sets the prices for the native ETH equivalent of Zbyte and the Zbyte price in Gwei.

_This function is restricted to be called only by authorized users._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nativeEthEquivalentZbyteInGwei_ | uint256 | The price of the native ETH equivalent of Zbyte in Gwei. |
| zbytePriceInGwei_ | uint256 | The price of Zbyte in Gwei. |

### setBurnRateInMill

```solidity
function setBurnRateInMill(uint256 burnRate_) public
```

Sets burn rate for invoke calls in mill
1 Unit = 1000 Mill

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| burnRate_ | uint256 | burn rate in mill |

## ZbyteVToken

_The ZBYT vERC20 contract_

### ZeroAddress

```solidity
error ZeroAddress()
```

error (0xd92e233d): Address is address(0)

### CannotSendEther

```solidity
error CannotSendEther()
```

error (0xbf064619): Contract cannot receive ether

### InvalidDestroyAddress

```solidity
error InvalidDestroyAddress(address, address, address)
```

error (b034fa06): The address sent for destroy is not valid

### LowRoyaltyBalance

```solidity
error LowRoyaltyBalance(address, uint256, uint256)
```

error (0x3ed95ea5): Address, current balance and amount be transferred

### PaymasterAddressSet

```solidity
event PaymasterAddressSet(address)
```

event (0xa16990bf) Paymaster address is set

### ZbyteDPlatAddressSet

```solidity
event ZbyteDPlatAddressSet(address)
```

event (0xcdb1d336) ZbyteDPlat address is set

### AllowUserSwapSet

```solidity
event AllowUserSwapSet(bool)
```

event (0x5cedee88) Allow user swap is set

### allowUserSwap

```solidity
bool allowUserSwap
```

### royaltyBalance

```solidity
mapping(address => uint256) royaltyBalance
```

### constructor

```solidity
constructor(address burner_) public
```

ZBYT ERC20 constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| burner_ | address | Burn account address (Tokens are locked here, not destroyed) |

### pause

```solidity
function pause() external
```

Pauses the contract (mint, transfer and burn operations are paused)

### unpause

```solidity
function unpause() external
```

Unpauses the paused contract

### setPaymasterAddress

```solidity
function setPaymasterAddress(address paymaster_) public
```

Set the paymaster (forwarder) address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paymaster_ | address | Paymaster contract address |

### setZbyteDPlatAddress

```solidity
function setZbyteDPlatAddress(address dplat_) public
```

Set the DPlat address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dplat_ | address | DPlat contract address |

### setAllowUserSwap

```solidity
function setAllowUserSwap(bool allowUserSwap_) public
```

Set allow user swap from vZBYT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| allowUserSwap_ | bool | DPlat contract address |

### transfer

```solidity
function transfer(address to_, uint256 value_) public returns (bool)
```

Transfer vERC20 from caller's account to receiver's account

_requiresAuth ensures that this call can be complely disabled, or only specific accounts can call_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to_ | address | Receiver account address |
| value_ | uint256 | Amount of tokens to be transferred |

### transferFrom

```solidity
function transferFrom(address from_, address to_, uint256 value_) public returns (bool)
```

Transfers tokens from a specified address to another address.

_requiresAuth ensures that this call can be complely disabled, or only specific accounts can call
 Allowing only specific accounts to perform transferFrom allows controlled transfer of vERC20 in future_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from_ | address | The address to transfer tokens from |
| to_ | address | The address to transfer tokens to |
| value_ | uint256 | The amount of tokens to transfer |

### royaltyTransferFrom

```solidity
function royaltyTransferFrom(address from_, address to_, uint256 value_) public returns (bool)
```

Transfers tokens from a specified address to another address.

_requiresAuth ensures that this call can be complely disabled, or only specific accounts can call
 Allowing only specific accounts to perform transferFrom allows controlled transfer of vERC20 in future_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from_ | address | The address to transfer tokens from |
| to_ | address | The address to transfer tokens to |
| value_ | uint256 | The amount of tokens to transfer |

### mint

```solidity
function mint(address to_, uint256 amount_) external returns (uint256)
```

mint vZBYT ERC20

_The forwarder charges user in this ERC20 token for the contract call.  Approve the tokens to dplat at mint itself._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to_ | address | Receiver address |
| amount_ | uint256 | Amount to mint to the address(to_) and approve to dplat |

### burn

```solidity
function burn(address from_, uint256 amount_) external returns (uint256)
```

Transfer vERC20 to 'burner' address

_requiresAuth ensures that this call can be complely disabled, or only specific accounts can call_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from_ | address | Sender address to burn tokens from |
| amount_ | uint256 | Amount to burn |

### destroy

```solidity
function destroy(address from_) external returns (uint256)
```

Destroy vERC20

_This is called during withdraw / reconciliation only.  Withdraw is allowed only from the paymaster or burner address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from_ | address | Paymaster/burner address from which tokens are destroyed |

### destroyRoyaltyVERC20

```solidity
function destroyRoyaltyVERC20(address from_, uint256 amount_) external returns (uint256)
```

Destroy vERC20

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from_ | address | Address from which tokens are destroyed |
| amount_ | uint256 | Amount of tokens to be destroyed |

### receive

```solidity
receive() external payable
```

receive function (reverts)

## IEscrowERC20

### InvalidRelay

```solidity
error InvalidRelay(address)
```

Caller is not a valid relay

### InvalidCallbackMessage

```solidity
error InvalidCallbackMessage(uint256, uint256, uint256, uint256)
```

error (0xd6facdff): The callback received was invalid

### InvalidCallbackAck

```solidity
error InvalidCallbackAck(uint256, bytes32, bool, uint256)
```

error (0xcd9d7bb0): The ack in callback received was not found

### InsufficientERC20ForDepositGas

```solidity
error InsufficientERC20ForDepositGas(uint256, uint256)
```

error (0xed3fc6b3): Insufficient ERC20 for Deposit operation.

### UnAuthorized

```solidity
error UnAuthorized(address)
```

error (0xb3922495): Unauthorized caller.

### vERC20AddressSet

```solidity
event vERC20AddressSet(address, uint256)
```

event (0x1a40ce6d): vERC20 contract address is set

### RelayWrapperAddressSet

```solidity
event RelayWrapperAddressSet(address)
```

event (0x95290bcc): Core relay wrapper contract address is set

### ERC20Deposited

```solidity
event ERC20Deposited(address, address, uint256, uint256, bytes32)
```

event (0xcae09af7): ERC20 tokens deposited

### ERC20DepositConfirmed

```solidity
event ERC20DepositConfirmed(bytes32, bool, uint256)
```

event (0xf64578a8): ERC20 tokens deposit confirmed

### ERC20Withdrawn

```solidity
event ERC20Withdrawn(address, address, address, uint256, bytes32)
```

event (0x8b923c21): ERC20 tokens withdrawn

### ERC20WithdrawFailed

```solidity
event ERC20WithdrawFailed(bytes32, bool, uint256)
```

event (0x9c33bbca): ERC20 tokens withdraw failed

### ERC20WithdrawConfirmed

```solidity
event ERC20WithdrawConfirmed(bytes32, bool, uint256)
```

event (0xf5a60bd1): ERC20 tokens withdraw confirmed

### TreasuryAddressSet

```solidity
event TreasuryAddressSet(address, address)
```

event (0x1db696c9): The Treasury address is set

### ERC20DepositFailedAndRefunded

```solidity
event ERC20DepositFailedAndRefunded(bytes32, bool, uint256)
```

event (0x82b9d61d): ERC20 tokens deposit failed and refund issued to depositor

### WorkerRegistered

```solidity
event WorkerRegistered(address, bool)
```

event (0x2ddb4d51): Worker is registered(true/false)

### getNonce

```solidity
function getNonce() external view returns (uint256)
```

### totalSupplyAllChains

```solidity
function totalSupplyAllChains() external view returns (uint256)
```

### totalSupply

```solidity
function totalSupply(uint256 chain_) external view returns (uint256)
```

### asset

```solidity
function asset() external view returns (address)
```

### callbackHandler

```solidity
function callbackHandler(uint256 chain_, bytes32 ack_, bool success_, uint256 retval_) external returns (uint256)
```

## IEnterprisePaymentPolicy

### isUserOrDappEligibleForPayment

```solidity
function isUserOrDappEligibleForPayment(address user_, address dapp_, bytes4 functionSig_, uint256 amount_) external view returns (bool)
```

### updateEnterpriseEligibility

```solidity
function updateEnterpriseEligibility(address user_, address dapp_, bytes4 functionSig_, int256 amount_) external returns (bool)
```

## IZbyteDPlat

### preExecute

```solidity
function preExecute(address user_, address dapp_, bytes4 functionSig_, uint256 chargeEth_) external returns (address)
```

### postExecute

```solidity
function postExecute(address payer_, bool executeResult_, uint256 reqValue_, uint256 gasConsumedEth_, uint256 preChargeEth_) external
```

## IZbytePriceFeeder

Interface for Zbyte price feeder, defining functions for gas cost conversion and retrieval.

### NativeEthEquivalentZbyteSet

```solidity
event NativeEthEquivalentZbyteSet(uint256 nativeEthEquivalentZbyteInGwei)
```

Event(0xec97c145) the equivalent Zbyte price for native ETH is set.

### ZbytePriceInGweiSet

```solidity
event ZbytePriceInGweiSet(uint256 zbytePriceInGwei)
```

Event(0xd12b5bd7) the Zbyte price in Gwei is set.

### BurnRateInMillSet

```solidity
event BurnRateInMillSet(uint256)
```

Event(0xabd3562e) the burn rate is set.

### convertEthToEquivalentZbyte

```solidity
function convertEthToEquivalentZbyte(uint256 ethAmount_) external view returns (uint256)
```

Converts eth to equivalent Zbyte amount.

_Example:
Say, Native Eth Price = 1$
Zbyte Price = 2¢
nativeEthEquivalentZbyteInGwei = 50,000,000,000 Gwei (i.e. 1 Native Eth = 50 Zbyte)
ethAmount_  = 1,000,000,000,000,000,000 Wei (1 Native Eth)
zbyteAmount = (1,000,000,000,000,000,000 * 50,000,000,000) / 1,000,000,000
            = 50,000,000,000,000,000,000 Wei (50 ZBYT)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ethAmount_ | uint256 | Amount of eth. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Equivalent Amount of zbyte. |

### convertMillToZbyte

```solidity
function convertMillToZbyte(uint256 priceInMill_) external view returns (uint256)
```

Converts price in millionths to Zbyte amount.

_Example:
Say, Unit Price = 1$
Zbyte Price = 2¢
So, zbytePriceEquivalentInGwei = 50,000,000,000 Gwei (i.e. 1 Unit = 50 Zbyte)
priceInMill_ = 20 Mill (i.e. (2 / 1000) Unit)
zbyteAmount = (20 * 50,000,000,000 * 1,000,000,000) / 1000
            = 1,000,000,000,000,000,000 Wei (1 ZBYT)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| priceInMill_ | uint256 | Price in millionths. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Equivalent Zbyte amount. |

### getDPlatFeeInZbyte

```solidity
function getDPlatFeeInZbyte() external view returns (uint256)
```

DPlat fee in terms of Zbyte
1 Unit = 1000 Mill

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | DPlat fee |

## IvERC20

_Interface for a contract representing a variation of the ERC20 token._

### burn

```solidity
function burn(address to, uint256 amount) external returns (uint256)
```

_Burns a specified amount of tokens by transferring them to the specified address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to which the tokens will be burned. |
| amount | uint256 | The amount of tokens to be burned. |

### mint

```solidity
function mint(address to, uint256 amount) external returns (uint256)
```

_Mints a specified amount of tokens and transfers them to the specified address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to which the tokens will be minted and transferred. |
| amount | uint256 | The amount of tokens to be minted. |

## IRelayWrapper

### performCrossChainCall

```solidity
function performCrossChainCall(uint256 relay_, uint256 srcChain_, uint256 destChain_, address destContract_, bytes destCallData_, bytes32 ack_, address callbackContract_, bytes relayParams_) external payable returns (bool)
```

### isValidRelay

```solidity
function isValidRelay(uint256 chainId, address relay_) external returns (bool)
```

### updatePayload

```solidity
function updatePayload(uint256 destChain_, address destContract_, bytes32 ack_, address callbackContract_, bytes data_) external pure returns (bytes)
```

## RelayWrapper

_The Relay wrapper to facilitate ZBYT deposit/mint_

### InvalidCallBackContract

```solidity
error InvalidCallBackContract()
```

error (0xeed987a0): The callback contract address is 0 but ack is set

### RelayContractNotSet

```solidity
error RelayContractNotSet(uint256, address, address)
```

error (0x089c2a3e): The relay contract address is not set for the given relay id

### CallerNotEscrow

```solidity
error CallerNotEscrow(address, address)
```

error (0x5c87504d): Caller is not the registered escrow

### EscrowAddressSet

```solidity
event EscrowAddressSet(address)
```

error (0x14229a64): Address of escrow contract is set

### RelayAddressSet

```solidity
event RelayAddressSet(uint256, uint256, address)
```

error (0xbe32fe92): Address of Relay is set for given chain id and relay id

### relayContract

```solidity
mapping(uint256 => mapping(uint256 => address)) relayContract
```

mapping of chain id => relay id => relay address

_relay id is an identifier for relay (e.g., 0 -> zbyte relay, 1 -> axelar, etc)_

### chainRelays

```solidity
mapping(uint256 => uint256[]) chainRelays
```

mapping of chain id => array of valid relay ids

### escrow

```solidity
address escrow
```

Registered escrow contract address

### constructor

```solidity
constructor(address forwarder_) public
```

Relay Wrapper constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | Forwarder contact address |

### onlyEscrow

```solidity
modifier onlyEscrow()
```

Modifier to check if the caller is the registered escrow

### setEscrowAddress

```solidity
function setEscrowAddress(address escrow_) public
```

Set the address of Escrow contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| escrow_ | address | Escrow contract address |

### setRelayAddress

```solidity
function setRelayAddress(uint256 chain_, uint256 relayid_, address relay_) public
```

Set the address of Relay contract

_set the relay address to 0 to disable the relay_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain_ | uint256 | Chain id for which the relay address is set |
| relayid_ | uint256 | Relay id for which relay address is set |
| relay_ | address | Relay contract Address |

### isValidRelay

```solidity
function isValidRelay(uint256 chain_, address relay_) external view returns (bool)
```

Verify if given relay is a valid one for the given chain id

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain_ | uint256 | Chain id for which the relay address is set |
| relay_ | address | Relay contract Address |

### performCrossChainCall

```solidity
function performCrossChainCall(uint256 relayid_, uint256 srcChain_, uint256 destChain_, address destContract_, bytes destCallData_, bytes32 ack_, address callbackContract_, bytes relayParams_) external payable returns (bool)
```

Initiate the cross chain call for deposit/mint

_This function can be called only the the registered escrow contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| relayid_ | uint256 | Relay id that should be used for this call |
| srcChain_ | uint256 | Chain id of source chain |
| destChain_ | uint256 | Chain id of destination chain |
| destContract_ | address | Address of contract to be called on destination chain |
| destCallData_ | bytes | Calldata for the call on destination chain |
| ack_ | bytes32 | Unique hash of the cross chain deposit/mint call |
| callbackContract_ | address | Address of contract on source chain to handle callback |
| relayParams_ | bytes | Additional data that can be sent to the relay |

### updatePayload

```solidity
function updatePayload(uint256 destChain_, address destContract_, bytes32 ack_, address callbackContract_, bytes data_) public pure returns (bytes)
```

Update the payload to include additional information

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destChain_ | uint256 | Chain id of destination chain |
| destContract_ | address | Address of contract to be called on destination chain |
| ack_ | bytes32 | Unique hash of the cross chain deposit/mint call |
| callbackContract_ | address | Address of contract on source chain to handle callback |
| data_ | bytes | original payload |

### _msgSender

```solidity
function _msgSender() internal view returns (address sender)
```

ERC2771 _msgSender override

### _msgData

```solidity
function _msgData() internal view returns (bytes)
```

ERC2771 _msgData override

## ZbyteRelay

_The Zbyte Relay contract_

### NotApproved

```solidity
error NotApproved(address)
```

error (0x0ca968d8): Caller is not an approved caller

### NotRelayWrapperOrSelf

```solidity
error NotRelayWrapperOrSelf(address, address)
```

error (0x26fb3778): Caller is not the RelayWrapper or this contract

### InvalidChain

```solidity
error InvalidChain(uint256, uint256)
```

error (0xc16b00ce): Current chain id does not match with the one sent in payload

### InvalidDestinationRelay

```solidity
error InvalidDestinationRelay(address, address)
```

error (0x4a01d2ac): Invalid destination relay

### RelayCallRemoteReceived

```solidity
event RelayCallRemoteReceived(uint256, address, uint256, address, bytes)
```

event (0x9a3d7ba1): Received the request to perform a remote call

### RelayReceiveCallExecuted

```solidity
event RelayReceiveCallExecuted(bytes, bool, uint256)
```

event (0xceeaa702): Executed the call request from a source chain

### RelayWrapperSet

```solidity
event RelayWrapperSet(address)
```

event (0x2658b600): Relay Wrapper address is set

### RelayApproveeAdded

```solidity
event RelayApproveeAdded(address)
```

event (0xe89d9bcd): Approvee address is set

### approved

```solidity
mapping(address => bool) approved
```

mapping of approved addresses.  Only these addresses can invoke the 'receiveCall'

### relayWrapper

```solidity
contract IRelayWrapper relayWrapper
```

Address of the RelayWrapper (on core)

### constructor

```solidity
constructor(address forwarder_) public
```

Zbyte Relay constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | Forwarder contact address |

### onlyApprovedOrSelf

```solidity
modifier onlyApprovedOrSelf()
```

Modifier to check if the caller is approved or this contract

### onlyRelayWrapperOrSelf

```solidity
modifier onlyRelayWrapperOrSelf()
```

Modifier to check if the caller is RelayWrapper or this contract

### setRelayWrapper

```solidity
function setRelayWrapper(address wrapper_) external
```

Set the RelayWrapper contract address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| wrapper_ | address | RelayWrapper contact address |

### addRelayApprovee

```solidity
function addRelayApprovee(address approvee_) external
```

Set the approvee address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| approvee_ | address | Address of the approvee |

### callRemote

```solidity
function callRemote(uint256 destChain_, address destRelay_, bytes payload_) public payable returns (bool)
```

Initiate the remote chain call

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destChain_ | uint256 | Chain id of destination chain |
| destRelay_ | address | Address of the trusted relay on destination chain |
| payload_ | bytes | Payload to be used for the destination call |

### receiveCall

```solidity
function receiveCall(uint256 srcChain_, address srcRelay_, bytes payload_) external returns (bool)
```

Handle the call received from source chain

_Call can be made only by approved accounts or self_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| srcChain_ | uint256 | Chain id of source chain |
| srcRelay_ | address | Address of the trusted relay on source chain |
| payload_ | bytes | Payload to be used for the call on this chain |

### updatePayload

```solidity
function updatePayload(uint256 destChain_, address destContract_, bytes32 ack_, address callbackContract_, bytes data_) public pure returns (bytes)
```

Update the payload to include additional information

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destChain_ | uint256 | Chain id of destination chain |
| destContract_ | address | Address of contract to be called on destination chain |
| ack_ | bytes32 | Unique hash of the cross chain deposit/mint call |
| callbackContract_ | address | Address of contract on source chain to handle callback |
| data_ | bytes | original payload |

### _msgSender

```solidity
function _msgSender() internal view returns (address sender)
```

ERC2771 _msgSender override

### _msgData

```solidity
function _msgData() internal view returns (bytes)
```

ERC2771 _msgData override

## OrderBook

_A decentralized order book contract for trading ERC20 tokens._

### base

```solidity
contract IERC20 base
```

### quote

```solidity
contract IERC20 quote
```

< The base ERC20 token for trading.

### Order

```solidity
struct Order {
  uint256 id;
  address trader;
  bool isBuyOrder;
  uint256 price;
  uint256 quantity;
  bool isFilled;
  address baseToken;
  address quoteToken;
}
```

### bidOrders

```solidity
struct OrderBook.Order[] bidOrders
```

### askOrders

```solidity
struct OrderBook.Order[] askOrders
```

< Array to store bid (buy) orders.

### OrderCanceled

```solidity
event OrderCanceled(uint256 orderId, address trader, bool isBuyOrder)
```

< Array to store ask (sell) orders.

### TradeExecuted

```solidity
event TradeExecuted(uint256 buyOrderId, uint256 sellOrderId, address buyer, address seller, uint256 price, uint256 quantity)
```

< Event emitted when an order is canceled.

### constructor

```solidity
constructor(address forwarder_) public
```

_Constructor to set the trusted forwarder._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | The address of the trusted forwarder. |

### placeBuyOrder

```solidity
function placeBuyOrder(uint256 price, uint256 quantity, address baseToken, address quoteToken) external
```

_Place a buy order._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | uint256 | The price per token of the order. |
| quantity | uint256 | The quantity of tokens in the order. |
| baseToken | address | The ERC20 token address for the base asset. |
| quoteToken | address | The ERC20 token address for the quote asset. |

### placeSellOrder

```solidity
function placeSellOrder(uint256 price, uint256 quantity, address baseToken, address quoteToken) external
```

_Place a sell order._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | uint256 | The price per token of the order. |
| quantity | uint256 | The quantity of tokens in the order. |
| baseToken | address | The ERC20 token address for the base asset. |
| quoteToken | address | The ERC20 token address for the quote asset. |

### cancelOrder

```solidity
function cancelOrder(uint256 orderId, bool isBuyOrder) external
```

_Cancel an existing order._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| orderId | uint256 | The ID of the order to cancel. |
| isBuyOrder | bool | Flag indicating if the order to cancel is a buy order. |

### insertBidOrder

```solidity
function insertBidOrder(struct OrderBook.Order newOrder) internal
```

_Internal function to insert a new buy order into the bidOrders array
while maintaining sorted order (highest to lowest price)._

### insertAskOrder

```solidity
function insertAskOrder(struct OrderBook.Order newOrder) internal
```

_Internal function to insert a new sell order into the askOrders array
while maintaining sorted order (lowest to highest price)._

### matchBuyOrder

```solidity
function matchBuyOrder(uint256 buyOrderId) internal
```

_Internal function to match a buy order with compatible ask orders._

### matchSellOrder

```solidity
function matchSellOrder(uint256 sellOrderId) internal
```

_Internal function to match a sell order with compatible bid orders._

### getBidOrderIndex

```solidity
function getBidOrderIndex(uint256 orderId) public view returns (uint256)
```

_Get the index of a buy order in the bidOrders array._

### getAskOrderLength

```solidity
function getAskOrderLength() public view returns (uint256)
```

### getBidOrderLength

```solidity
function getBidOrderLength() public view returns (uint256)
```

### getAskOrderIndex

```solidity
function getAskOrderIndex(uint256 orderId) public view returns (uint256)
```

_Get the index of a sell order in the askOrders array._

### min

```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256)
```

_Helper function to find the minimum of two values._

## SampleDstoreDapp

This contract serves as a sample data storage decentralized application (DApp).
It allows users to store a uint8 value along with the address of the entity performing the storage operation.
To prepare a contract for DPlat compatibility:
1. Users are required to derive from the abstract contract called ZbyteContext.
2. Replace the usage of msg.sender with _msgSender() and msg.data with _msgData().

### DStoreSet

```solidity
event DStoreSet(address, uint256)
```

_Emitted when a value is stored._

### storedValue

```solidity
uint8 storedValue
```

Stored uint8 value

### storedBy

```solidity
address storedBy
```

Address of the entity that stored the value

### constructor

```solidity
constructor(address forwarder_) public
```

Constructor to set the trusted forwarder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | The address of the trusted forwarder |

### storeValue

```solidity
function storeValue(uint8 _value) public
```

Function to store a uint8 value

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _value | uint8 | The uint8 value to be stored |

## Auth

This abstract contract defines role-based access control (RBAC) mechanisms
to manage user roles and capabilities within a smart contract system.

### UserRoleUpdated

```solidity
event UserRoleUpdated(address user, uint8 role, bool enabled)
```

Emitted when a user role is updated.

### PublicCapabilityUpdated

```solidity
event PublicCapabilityUpdated(bytes4 functionSig, bool enabled)
```

Emitted when a public capability is updated.

### RoleCapabilityUpdated

```solidity
event RoleCapabilityUpdated(uint8 role, bytes4 functionSig, bool enabled)
```

Emitted when a role capability is updated.

### DiamondStorage

```solidity
struct DiamondStorage {
  mapping(address => bytes32) getUserRoles;
  mapping(bytes4 => bool) isCapabilityPublic;
  mapping(bytes4 => bytes32) getRolesWithCapability;
}
```

### diamondStorage

```solidity
function diamondStorage() internal pure returns (struct Auth.DiamondStorage ds)
```

### getOwner

```solidity
function getOwner() public virtual returns (address)
```

Internal function to access the diamond storage.

### doesUserHaveRole

```solidity
function doesUserHaveRole(address user, uint8 role) public view returns (bool)
```

Checks if a user has a specific role.

### doesRoleHaveCapability

```solidity
function doesRoleHaveCapability(uint8 role, bytes4 functionSig) public view returns (bool)
```

Checks if a role has access to a specific capability.

### canCall

```solidity
function canCall(address user, bytes4 functionSig) public view returns (bool)
```

Checks if a user can call a specific function.

### isAuthorized

```solidity
function isAuthorized(address user, bytes4 functionSig) internal view returns (bool)
```

Checks if a user is authorized to call a specific function.

### isAuthorizedOrOwner

```solidity
function isAuthorizedOrOwner(address user, bytes4 functionSig) internal returns (bool)
```

Checks if a user is authorized to call a specific function or is the owner.

### requiresAuth

```solidity
modifier requiresAuth()
```

Modifier to require authentication for a function call.

### requiresAuthOrOwner

```solidity
modifier requiresAuthOrOwner()
```

Modifier to require authentication or ownership for a function call.

### setPublicCapability

```solidity
function setPublicCapability(bytes4 functionSig, bool enabled) public
```

Sets the public access status of a capability.

### setRoleCapability

```solidity
function setRoleCapability(uint8 role, bytes4 functionSig, bool enabled) public
```

Sets the access status of a capability for a specific role.

### setUserRole

```solidity
function setUserRole(address user, uint8 role, bool enabled) public
```

Sets the role of a user.

## AuthDiamond

Abstract function to retrieve the owner address.

### getOwner

```solidity
function getOwner() public virtual returns (address)
```

Internal function to access the diamond storage.

## AuthSimple

### getOwner

```solidity
function getOwner() public virtual returns (address)
```

Internal function to access the diamond storage.

## LibCommonErrors

### ZeroAddress

```solidity
error ZeroAddress()
```

### NotOwner

```solidity
error NotOwner()
```

### Unauthorized

```solidity
error Unauthorized()
```

### ArraySizeMismatched

```solidity
error ArraySizeMismatched(uint256, uint256)
```

## LibZbyteForwarderFacet

The Zbyte Forwarder Facet

_The Zbyte Forwarder Facet_

### DiamondStorage

```solidity
struct DiamondStorage {
  address trustedForwarder;
}
```

### diamondStorage

```solidity
function diamondStorage() internal pure returns (struct LibZbyteForwarderFacet.DiamondStorage ds)
```

Retrieves the DiamondStorage struct for the library.

_trustedForwarder: Address of the trusted forwarder_

### _setTrustedForwarder

```solidity
function _setTrustedForwarder(address forwarder_) internal
```

Sets the address of trusted forwarder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address |  |

### _getTrustedForwarder

```solidity
function _getTrustedForwarder() internal view returns (address)
```

Gets the address of trusted forwarder

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder_) internal view returns (bool)
```

Checks if the given forwarder is the trusted forwarder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address |  |

## ZbyteContext

_ERC2771Context with a function to set forwarder_

### CannotSendEther

```solidity
error CannotSendEther()
```

error (0xbf064619): Contract cannot receive ether

### ZeroAddress

```solidity
error ZeroAddress()
```

error (0xd92e233d): Address is address(0)

### ZeroValue

```solidity
error ZeroValue()
```

error(): Value sent is 0

### ForwarderSet

```solidity
event ForwarderSet(address, address)
```

event (0x94aed472): Forwarder address is changed

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder_) public view virtual returns (bool)
```

Check if the given address is the trusted forwarder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | Address to check |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | true if forwarder_ is trusted forwarder |

### _setTrustedForwarder

```solidity
function _setTrustedForwarder(address forwarder_) internal
```

Set a trusted forwarder address

_emits ForwarderSet on success_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | Trusted forwarder address |

### setTrustedForwarder

```solidity
function setTrustedForwarder(address forwarder_) public
```

Set the forwarder contract address

_onlyOwner can call_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | Frwarder conract address |

### _getTrustedForwarder

```solidity
function _getTrustedForwarder() internal view returns (address)
```

Get the trusted forwarder address

### _msgSender

```solidity
function _msgSender() internal view virtual returns (address sender)
```

Extract true caller if called via trusted forwarder

### _msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

Extract data if called via trusted forwarder

## ZbyteContextDiamond

### NotAForwarder

```solidity
error NotAForwarder()
```

error (0x5ac85bab): Caller is not a forwarder

### onlyOwner

```solidity
modifier onlyOwner()
```

modifier to enforce that the caller is the owner

### onlyForwarder

```solidity
modifier onlyForwarder()
```

modifier to enforce that the caller is the forwarder

### _msgSender

```solidity
function _msgSender() internal view returns (address ret)
```

Extract true caller if called via trusted forwarder

### _msgData

```solidity
function _msgData() internal view returns (bytes ret)
```

Extract data if called via trusted forwarder

## ZbyteForwarderFacet

### ForwarderSet

```solidity
event ForwarderSet(address)
```

event (0x94aed472): Forwarder address is changed

### setForwarder

```solidity
function setForwarder(address forwarder_) public
```

Set the address of trusted forwarder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| forwarder_ | address | Address of the trusted forwarder |

### getTrustedForwarder

```solidity
function getTrustedForwarder() public view returns (address)
```

Get the address of trusted forwarder

