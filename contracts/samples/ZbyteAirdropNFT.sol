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

import "../utils/ZbyteContext.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Zbyte's Airdrop NFT contract for DPLAT
contract ZbyteAirdropNFT is ZbyteContext, ERC721, ERC721URIStorage, ERC721Pausable, ERC721Enumerable {
  using SafeERC20 for IERC20;

  uint256 private _nextTokenId;
  address public erc20Address;
  uint256 public erc20PerToken;
  address public distributor;
  string public uriBase;
  uint256 public royaltyPerToken;
  address public royaltyReceiver;
  address public dplatToken;

  event mintedForAirdrop(uint256,uint256);
  event Redeemed(address,uint256);
  event Pause();
  event Unpause();
  event RoyaltyReceiverSet(address indexed newRoyaltyReceiver);
  event DPlatTokenSet(address indexed newDPlatToken);
  event RoyaltyPerTokenSet(uint256 indexed newRoyaltyPerToken);
  event Erc20PerTokenSet(uint256 indexed newErc20PerToken);

  // Errors
  error UserNumTokenRestriction(address,uint256);
  error TokenDoesNotExist(uint256,address);

  // Modifiers
  modifier onlyForwarder {
    // Remove this restriction for now.
    //require(isTrustedForwarder(msg.sender),"Call not from Forwarder");
    _;
  }

  /**
   * @dev Constructor to initialize the contract.
   * @param erc20Address_ Address of the ERC20 token used for rewards.
   * @param erc20PerToken_ Amount of ERC20 tokens to be rewarded per NFT.
   * @param royaltyPerToken_ Amount of royalty to be paid per NFT.
   * @param royaltyReceiver_ Address to receive royalties.
   * @param dplatTokenAddress_ Address of the DPLAT token.
   * @param distributor_ Address of the distributor for airdrops.
   * @param baseUri_ Base URI for token metadata.
   */
  constructor(address erc20Address_,
              uint256 erc20PerToken_,
              uint256 royaltyPerToken_,
              address royaltyReceiver_,
              address dplatTokenAddress_,
              address distributor_,
              string memory baseUri_)
              ERC721("DPLAT Airdrop","DPLATAIR") {
    if(erc20Address_ == address(0) || royaltyReceiver_ == address(0) || dplatTokenAddress_ == address(0))
      revert ZeroAddress();

    erc20Address = erc20Address_;
    royaltyReceiver = royaltyReceiver_;
    royaltyPerToken = royaltyPerToken_;
    erc20PerToken = erc20PerToken_;
    distributor = distributor_;
    dplatToken = dplatTokenAddress_;
    uriBase = baseUri_;
    _nextTokenId = 1;
  }

  /**
   * @dev Internal function to get the base URI.
   * @return The base URI.
   */  
  function _baseURI() internal view override returns (string memory) {
    return uriBase;
  }

  /**
   * @dev Function to check if an address supports a particular interface.
   * @param interfaceId The interface identifier.
   * @return True if the interface is supported, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Function to pause the contract. Only callable by the owner.
   */
  function pause() public onlyOwner {
    _pause();
    emit Pause();
  }

  /**
   * @dev Function to set the royalty receiver. Only callable by the owner.
   * @param royaltyReceiver_ Address to receive royalties.
   */
  function setRoyaltyReceiver(address royaltyReceiver_) public onlyOwner {
    if(royaltyReceiver_ == address(0))
      revert ZeroAddress();
    royaltyReceiver = royaltyReceiver_;
    emit RoyaltyReceiverSet(royaltyReceiver_);
  }

  /**
   * @dev Function to set the DPLAT token address. Only callable by the owner.
   * @param dplatTokenAddress_ Address of the DPLAT token.
   */
  function setDPlatToken(address dplatTokenAddress_) public onlyOwner {
    if(dplatTokenAddress_ == address(0))
      revert ZeroAddress();
    dplatToken = dplatTokenAddress_;
    emit DPlatTokenSet(dplatToken);
  }

  /**
   * @dev Function to set the royalty amount per token. Only callable by the owner.
   * @param royaltyPerToken_ Amount of royalty to be paid per NFT.
   */
  function setRoyaltyPerToken(uint256 royaltyPerToken_) public onlyOwner {
    royaltyPerToken = royaltyPerToken_;
    emit RoyaltyPerTokenSet(royaltyPerToken);
  }

  /**
   * @dev Function to set the ERC20 reward amount per token. Only callable by the owner.
   * @param erc20PerToken_ Amount of ERC20 tokens to be rewarded per NFT.
   */
  function setERC20PerToken(uint256 erc20PerToken_) public onlyOwner {
    erc20PerToken = erc20PerToken_;
    emit Erc20PerTokenSet(erc20PerToken);
  }

  /**
   * @dev Function to unpause the contract. Only callable by the owner.
   */
  function unpause() public onlyOwner {
    _unpause();
    emit Unpause();
  }

  /**
   * @dev Internal function to safely mint NFTs for airdrop.
   * @param to The address to receive the minted NFTs.
   * @param uri URI for the minted NFTs.
   */
  function safeMint(address to, string memory uri) internal {
    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  /**
   * @dev Function to perform actions before a token transfer.
   * @param from The address from which the tokens are transferred.
   * @param to The address to which the tokens are transferred.
   * @param tokenId The ID of the token being transferred.
   */
  function _beforeTokenTransfer(address from,
                                address to,
                                uint256 tokenId)
    internal onlyForwarder
    override(ERC721, ERC721Pausable, ERC721Enumerable) {
      ERC721Pausable._beforeTokenTransfer(from,to,tokenId);
      ERC721Enumerable._beforeTokenTransfer(from,to,tokenId);
  }

  /**
   * @dev Internal function to burn a token.
   * @param tokenId The ID of the token to be burned.
   */
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    ERC721URIStorage._burn(tokenId);
  }

  /**
   * @dev Function to get the sender of the current message.
   * @return sender The address of the sender.
   */
  function _msgSender() internal view override(ZbyteContext,Context) returns (address sender) {
    return ZbyteContext._msgSender();
  }

  /**
   * @dev Function to get the data of the current message.
   * @return The data of the current message.
   */
  function _msgData() internal view override(ZbyteContext,Context) returns (bytes calldata) {
    return ZbyteContext._msgData();
  }

  /**
   * @dev Function to get the token URI for a given token ID.
   * @param tokenId The ID of the token.
   * @return The token URI.
   */
  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }

  /**
   * @dev Function to mint NFTs for an airdrop. Only callable by the owner.
   * @param numTokens The number of tokens to mint for the airdrop.
   * @param airdropUri The URI for the minted NFTs.
   */
  function mintForAirdrop(uint256 numTokens,string memory airdropUri)
      public onlyOwner
      onlyForwarder whenNotPaused {
    uint256 startTokenId = _nextTokenId;
    for(uint256 i=0 ; i<numTokens ; i++) {
      safeMint(distributor,airdropUri);
    }
    emit mintedForAirdrop(numTokens,startTokenId);
  }

  /**
   * @dev Function to redeem NFTs and receive rewards.
   * @param receiver The address to receive the rewards.
   */
  function redeem(address receiver) public onlyForwarder {
    address user = _msgSender();
    if (receiver == address(0)) {
      revert ZeroAddress();
    }
    uint256 numTokens = ERC721.balanceOf(user);
    for (uint256 i=0 ; i < numTokens; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(user,i);
      _burn(tokenId);
    }
    IERC20(erc20Address).safeTransfer(receiver,erc20PerToken*numTokens);
    IERC20(dplatToken).safeTransferFrom(user,royaltyReceiver,royaltyPerToken*numTokens);

    emit Redeemed(_msgSender(),numTokens);
  }

  /**
   * @dev Function to transfer remaining ERC20 tokens to a specified recipient. Only callable by the owner.
   * @param recepient The address to receive the remaining ERC20 tokens.
   */
  function transferRemainingERC20(address recepient) public onlyOwner {
    uint256 balance =  IERC20(erc20Address).balanceOf(address(this));
    IERC20(erc20Address).safeTransfer(recepient,balance);
  }
}