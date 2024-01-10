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
  uint256 erc20PerToken;
  address distributor;
  string uriBase;
  uint256 public royaltyPerToken;
  address public royaltyReceiver;
  address public dplatToken;

  event mintedForAirdrop(uint256,uint256);
  event Redeemed(address,uint256);

  error UserNumTokenRestriction(address,uint256);
  error TokenDoesNotExist(uint256,address);

  modifier onlyForwarder {
    require(isTrustedForwarder(msg.sender),"Call not from Forwarder");
    _;
  }

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
  
  function _baseURI() internal view override returns (string memory) {
    return uriBase;
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function setRoyaltyReceiver(address royaltyReceiver_) public onlyOwner {
    if(royaltyReceiver_ == address(0))
      revert ZeroAddress();
    royaltyReceiver = royaltyReceiver_;
  }

  function setDPlatToken(address dplatTokenAddress_) public onlyOwner {
    if(dplatTokenAddress_ == address(0))
      revert ZeroAddress();
    dplatToken = dplatTokenAddress_;
  }

  function setRoyaltyPerToken(uint256 royaltyPerToken_) public onlyOwner {
    royaltyPerToken = royaltyPerToken_;
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function safeMint(address to, string memory uri) internal {
    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  function _beforeTokenTransfer(address from,
                                address to,
                                uint256 tokenId)
    internal onlyForwarder
    override(ERC721, ERC721Pausable, ERC721Enumerable) {
      ERC721Pausable._beforeTokenTransfer(from,to,tokenId);
      ERC721Enumerable._beforeTokenTransfer(from,to,tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    ERC721URIStorage._burn(tokenId);
  }

  /// @notice ERC2771 _msgSender override
  function _msgSender() internal view override(ZbyteContext,Context) returns (address sender) {
    return ZbyteContext._msgSender();
  }

  /// @notice ERC2771 _msgData override
  function _msgData() internal view override(ZbyteContext,Context) returns (bytes calldata) {
    return ZbyteContext._msgData();
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }

  function mintForAirdrop(uint256 numTokens,string memory airdropUri)
      public onlyOwner
      onlyForwarder whenNotPaused {
    uint256 startTokenId = _nextTokenId;
    for(uint256 i=0 ; i<numTokens ; i++) {
      safeMint(distributor,airdropUri);
    }
    emit mintedForAirdrop(numTokens,startTokenId);
  }

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

  function transferRemainingERC20(address recepient) public onlyOwner {
    uint256 balance =  IERC20(erc20Address).balanceOf(address(this));
    IERC20(erc20Address).safeTransfer(recepient,balance);
  }
}