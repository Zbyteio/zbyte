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

/**
 * @title IvERC20
 * @dev Interface for a contract representing a variation of the ERC20 token.
 */
interface IvERC20 is IERC20 {
    
    /**
     * @dev Burns a specified amount of tokens by transferring them to the specified address.
     * @param to The address to which the tokens will be burned.
     * @param amount The amount of tokens to be burned.
     */
    function burn(address to, uint256 amount) external returns(uint256);
    
    /**
     * @dev Mints a specified amount of tokens and transfers them to the specified address.
     * @param to The address to which the tokens will be minted and transferred.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address to, uint256 amount) external returns(uint256);
}