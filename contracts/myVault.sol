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

    uint public ethPrice = 0; // This will be updated by our oracles. 
    uint public usdTargetPercentage = 40; // Portfolio set to 40% DAI, 60% ETH, this is custom.
    uint public usdDividendPercentage = 25; // 25% of 40% = 10% annual drawdown. 
    uint private dividendFrequency = 3 minutes; // Change to 1 year for production, number of secs in 3 mins
    uint public nextDividendTS; // Set in the constructor
    address public owner; // Owner of contract, pay for gas

    using SafeERC20 for IERC20; // library
    using SafeERC20 for DepositableERC20; // library

    IERC20 daiToken = IERC20(daiAddress); // Declaring tokens, standard
    DepositableERC20 wethToken = DepositableERC20(wethAddress); // Depositable token for WETH
    IQuoter quoter = IQuoter(uinswapV3QuoterAddress);
    IUniswapRouter uniswapRouter = IUniswapRouter(uinswapV3RouterAddress);

    event myVaultLog(string msg, uint ref); // This will transaction log events to etherscan. 

    constructor() {
        console.log('Deploying myVault version: ', version);
        nextDividendTS = block.timestamp + dividendFrequency; // 
        owner = msg.sender; // Owner is the deployer of the contracts
    }

    function getDaiBalance() public view returns (uint) {
        return daiToken.balanceOf(address(this));
    }

    function getWethBalance() public view returns (uint) {
        return wethToken.balanceOf(address(this));
    }

    function getTotalBalance() public view returns (uint) {
        require(ethPrice > 0, 'ETH price has not been set'); 

        uint daiBalance = getDaiBalance(); // Get balance
        uint wethBalance = getWethBalance(); // Get balance
        uint wethUSD = wethBalance * ethPrice; // Brings us to USD units, assumes both assets have 18 decimals.
        uint totalBalance = wethUSD + daiBalance; // Adding USD for total

        return totalBalance;
    }

    // GETTING PRICE DATA FROM UNISWAP AND CHAINLINK:
    function updateEthPriceUniswap() public returns (uint) {
        uint ethPriceRaw = quoter.quoteExactOutputSingle(daiAddress, wethAddress, 3000, 100000, 0); 
        // Uses uniswap method to get quote, function of uniswap contract. This gives us a quote for our transaction. 
        ethPrice = ethPriceRaw / 100000;
        return ethPrice;
    }

    function updateEthpriceChainlink() public returns (uint) {
        int256 chainLinkEthPrice = EACAggregatorProxy(chainLinkETHUSDAddress).latestAnswer();
        // Get latest using EACAgg. function for chainlink
        ethPrice = uint(chainLinkEthPrice / 100000000);
        // Switching from a signed integer to an unsigned integer so matches uniswap function
        return ethPrice;
    }

    // FUNCTION TO CARRY OUT UNISWAP TRANSACTION: Take DAI and purchase WETH
    function buyWeth(uint amountUSD) internal {
        uint256 deadline = block.timestamp + 15;
        uint24 fee = 3000; 
        address recipient = address(this); 
        uint256 amountIn = amountUSD; 
        uint256 amountOutMinimum = 0; // Accounts for slippage 
        uint160 sqrtPriceLimitX96 = 0;

        emit myVaultLog('amountIn', amountIn); // Amount in that adds to transaction log so we can see for debugging. 

        require(daiToken.approve(address(uinswapV3RouterAddress), amountIn), 'DAI approve failed');
        // For ERC20 we actually have to approve to spend the token on the uniswap router, .approve function does this
        // .approve belongs to erc20 token as method
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            daiAddress,
            wethAddress,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );
        uniswapRouter.exactInputSingle(params);
        uniswapRouter.refundETH();
    }

    // FUNCTION TO CARRY OUT UNISWAP TRANSACTION: Take WETH and purchase DAI
    function sellWeth(uint amountUSD) internal {
        uint256 deadline = block.timestamp + 15;
        uint24 fee = 3000; 
        address recipient = address(this); 
        uint256 amountOut = amountUSD; 
        uint256 amountInMaximum = 10 ** 28; // Accounts for slippage 
        uint160 sqrtPriceLimitX96 = 0;

        require(wethToken.approve(address(uinswapV3RouterAddress), amountOut), 'WETH approve failed');
        // For ERC20 we actually have to approve to spend the token on the uniswap router, .approve function does this
        // .approve belongs to erc20 token as method
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
            wethAddress,
            daiAddress,
            fee,
            recipient,
            deadline,
            amountOut,
            amountInMaximum,
            sqrtPriceLimitX96
        );
        uniswapRouter.exactOutputSingle(params);
        uniswapRouter.refundETH();
    }

    // KEEPS LP IN 60 40 STRATEGY:
    function rebalance() public {
        require(msg.sender == owner, 'Only the power can rebalance their account');
        uint usdBalance = getDaiBalance();
        uint totalBalance = getTotalBalance();
        uint usdBalancePercentage = 100 * usdBalance / totalBalance;
        
        emit myVaultLog('usdBalancePercentage', usdBalancePercentage);

        // REBALANCING IF NOT MEETING TARGETS FOR POOL: 
        if (usdBalancePercentage < usdTargetPercentage) {
            uint amountToSell = totalBalance / 100 * (usdTargetPercentage - usdBalancePercentage);
            emit myVaultLog('amount to sell', amountToSell);
            require(amountToSell > 0, 'Nothing to sell');
            sellWeth(amountToSell);
        } else {
            uint amountToBuy = totalBalance / 100 * (usdBalancePercentage - usdTargetPercentage);
            emit myVaultLog('amount to buy', amountToBuy);
            require(amountToBuy > 0, 'Nothing to buy');
            buyWeth(amountToBuy);
        }
    }

    // 3 minute time period
    function annualDividend() public {
        require(msg.sender == owner, 'Only the owner can drawdown their account');
        require(block.timestamp > nextDividendTS, 'Dividend is not yet due');
        uint balance = getDaiBalance();
        uint amount = (balance * usdDividendPercentage) / 100; 
        nextDividendTS = block.timestamp + dividendFrequency; 
        daiToken.safeTransfer(owner, amount); // Part of open zepellin library
    }

    // Optional, removes entire weth and dai balances from accounts:
    function closeAccount() public {
        require(msg.sender == owner, 'Only the owner can close their account');
        uint daiBalance = getDaiBalance();
        if (daiBalance > 0) {
            daiToken.safeTransfer(owner, daiBalance);
        }
        uint wethBalance = getWethBalance();
        if (wethBalance > 0) {
            wethToken.safeTransfer(owner, wethBalance);
        }
    }

    receive() public {
        // Accept ETH, do nothing as it would break the gas fee for a transaction. 
    };

    function wrapETH() public {
        require(msg.sender == owner, 'Only the owner can convert ETH to WETH');
        uint ethBalance = address(this).balance;
        
        require(ethBalance > 0, "No ETH available to wrap");
        emit myVaultLog('wrap ETH', ethBalance);

        wethToken.deposit{ 
            value: ethBalance
        } ();
    };
};