# Dollet

This project's main purpose is to create different Defi investment strategies that allows users to invest their crypto on several protocols. For example on curve finance + convex finance.

## Admin structures

For all the strategies deployed on the same blockchain there will be a single super admin in the contracts that has access to make changes in all the editable values.
Also, this super admin will be able to add a list of admins. These admins will have access to make changes only in some functions.
The idea is to make these super admin and admins as multisignature wallets of trusted entities for dolllet.

What files are involved?

- contracts/admin/SuperAdmin.sol
- contracts/admin/AdminStructure.sol

## Strategies

Some implemented strategies are:

- USDC+USDT (Curve+Convex) Arbitrum
- USDT+CRVUSD (Curve+Convex) Ethereum
- USDC+CRVUSD (Curve+Convex) Ethereum
- USDC+WTBC+ETH (Curve+Convex) Ethereum

The strategies perfom a compounding of the rewards to maximize the rewards of the users, the function for compounding is executed every time a user deposits, claims, or withdraws, this will ensure that the user won't take rewards from the previous users and take the maximum amount of rewards. Also there is a function called harvest() that can be used by anyone to manually compound the rewards.

The super admin is able to enable and disable the charging of fees on the system. IT can charge a performance fee which is based on the reward only, and also management fee which is based on the body of the deposit, these fee percentages can be adjusted

## USDC+USDT Curve Convex - Arbitrum - Strategy #1

The way this strategy works is that a user deposits either USDC or USDC into the Yield Pool (Vault), the user will get some LP tokens in exchange to represent his shares, these LP tokens are not transferrable. The funds deposited by the users will be invested in other protocols, look at the steps below:

- A user can deposit multiple times using USDC or USDT, to keep consistency the funds are converted automatically to want which is the LP from curve finance for example USDC/USDT 2CRV.
- The USDC/USDT 2CRV token is later deposited on Convex finance, Convex finance boosts the tokens in his booster an returns CRV and CVX as reward tokens. Currently, Convex is only paying rewards in CRV but the strategy supports both of them.
- After some time, the Convex booster will accrue rewards for the depositors.
- To compound the rewards, the strategy will claim the rewards in CRV or CVX swap them for USDC and reinvest them as explained previously. Due to this reinvestment the previous depositors will accrue more and more rewards, the rewards in this strategy are paid in either USDC or USDT, the user can choose.

What files are involved?

- contracts/vaults/DolletVault.sol
- contracts/strategies/curve/StrategyConvexBicryptoL2.sol
- contracts/strategies/curve/StrategyCalculationsL2.sol
- contracts/strategies/common/StratFeeManager.sol
- contracts/utils/UniV3Actions.sol

## USDT+CRVUSD Curve Convex - Ethereum - Strategy #2

The way this strategy works is that a user deposits either USDT or CRVUSD into the Yield Pool (Vault), the user will get some LP tokens in exchange to represent his shares, these LP tokens are not transferrable. The funds deposited by the users will be invested in other protocols, look at the steps below:

- A user can deposit multiple times using USDT or CRVUSD, to keep consistency the funds are converted automatically to want which is the LP from curve finance for example USDT/CRVUSD.
- The USDC/CRVUSD token is later deposited on Convex finance, Convex finance boosts the tokens in his booster an returns CRV and CVX as reward tokens.
- After some time, the Convex booster will accrue rewards for the depositors.
- To compound the rewards, the strategy will claim the rewards in CRV or CVX swap them for USDT and reinvest them as explained previously. Due to this reinvestment the previous depositors will accrue more and more rewards, the rewards in this strategy are paid in either USDT or CRVUSD, the user can choose.

What files are involved?

- contracts/vaults/DolletVault.sol
- contracts/strategies/curve/StrategyConvexBicryptoL1.sol
- contracts/strategies/curve/StrategyCalculationsL1.sol
- contracts/strategies/common/StratFeeManager.sol
- contracts/utils/UniV3Actions.sol

## USDC+CRVUSD Curve Convex - Ethereum - Strategy #3

This strategy works in the same way as the strategy #2 the difference is that it changes USDT for USDC, so that means that it also uses a different Curve and Convex pools. These two strategies use the same contracts but different inputs.

What files are involved?

- contracts/vaults/DolletVault.sol
- contracts/strategies/curve/StrategyConvexBicryptoL1.sol (same as strategy #2)
- contracts/strategies/curve/StrategyCalculationsL1.sol
- contracts/strategies/common/StratFeeManager.sol
- contracts/utils/UniV3Actions.sol

## Estimations

Since this contract interacts with other protocols like curve or uniswap, the deposits, withdrawals, swaps, claims are affected by slippage. These contracts have different functions that allow the users to estimate on the action that he wants to perform what are the values that he will get, for this they have a slippage percentage, using the percentage it will show for example the minimum expected amount on a swap, then the minimum of LP tokens from curve. These values need to be used during the real transaction to make sure that the minimum expected amounts are specified.
