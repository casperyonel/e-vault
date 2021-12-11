//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// A vault to automate and decentralize a long term donation strategy

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20 interface
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Safe transfer, etc.
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol"; // Carry out swap on uniswap
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol"; // Price oracle to get price directly from exchange

// EACAggregatorProxy is used for chainlink oracle: 
interface EACAggregatorProxy {
    function latestAnswer() external view returns (int256); // For chainlink oracle
}

// Uniswap v3 Interface: 
interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable; // Call this at the end of a swap
}

// Add deposit function for wETH:
interface DepositableERC20 is IERC20 {
    function deposit() external payable;
}

contract myVault {
  uint public version = 1;
  /* Kovan Addresses */
  address public daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
  address public wethAddress = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
  address public uinswapV3QuoterAddress = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
  address public uinswapV3RouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address public chainLinkETHUSDAddress = 0x9326BFA02ADD2366b30bacB125260Af641031331;

}