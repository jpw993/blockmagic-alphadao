## AlphaDAO


**AlphaDAO is a POC project for on-chain token investment management**



## Presentations
Pitch video: https://www.youtube.com/watch?v=CIBj__Ztkqo

Smart contract demo video: https://www.youtube.com/watch?v=b_yNMQLSNvE

Slides: https://www.canva.com/design/DAGGJ964go8/CEjADSPTdBgIqc5ty9_f-g/view


## Short Description
This project contains a Solidity smart contract for creating, participating in, and managing an on-chain token asset management fund. The fees paid to the investment managers who have the fund are calculated based on the outperformance of the Consumer Price Index (which is provided from the Chainlink data feed).


## Full Description
The objective of asset management firms is to provide returns on cash deposited by investors. The investors benefit from the returns, which aim to beat keeping your money in a deposit account, and the asset managers benefit from a performance-based commission for providing this service.

In TradFi this operates on a model of trust; investors trust that the asset managers do not run away with their cash, that the cash is only traded in certain assets, and that defined risk limits are not breached.

AlphaDAO is a protocal that allows groups of traders (called "asset managers" in TradFi) to setup their organisations on-chain via a DAO (decentralised autonomous organization). This provides the following advantages:
- Security: tokens are locked in smart contracts, and transfer logic is pre-defined.
- Openness: anyone can be an asset manager or investor.
- Accountability: all trade transactions are recorded and visible on-chain.
- Voting rights: members can cast votes for actions such as removing a trader.


Additionally, the AlphaDAO project aims to bring the best practices from TradFi asset management to DeFi, including:
- Diversified teams with capital allocations [POC done]
- Performance fees based on outperformance CPI benchmark [POC done]
- Risk limits [Todo]
- Token restrictions [Todo]
- Lock-in and notice periods [Todo]


## Chainlink integration
We use CPI (consumer price index) from ChainLink to benchmark the trading performance of the investment managers.
The data feed used is: https://data.chain.link/feeds/ethereum/mainnet/consumer-price-index 



## Testnet Deployment
Scroll Sepolia: https://sepolia.scrollscan.com/address/0xc91fcb9ddd574f70c5c9594d1d0ac76c643a5082

## Technical Details

This project has been setup using the Foundry project template.


### Run unit tests

```shell
$ forge test
```
