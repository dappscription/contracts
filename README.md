<div align="center">
  <h1 align="center"> Dappscription</h1>
  <h4 align="center"> Bring Subscription Services to Web3</h4>
  <p align="center">
    <!-- badge goes here -->
  </p>

<p align='center'>
    <img src='https://i.imgur.com/kURIGos.jpg' alt='subscribe' width="500" />
</p>  
<h6 align="center"> Built with Foundry</h6>
  
</div>

## Introduction

Dappscription is an easy-to-use service for buliders to create and monetize subscription-based services.

Smart contracts are supposed to be immutable, but **services**, or products, are not. We believe that products that utilize smart contracts should keep iterating and provide the best services to the users, and we are here to provide the infra to make that easier for every devs to sustain their business, and focus on building.

### I'm a Service Provider

As a service provider (protocol, aggregators, frontend devs), you can register your project here with a simple `createPlan` call with your plan detail. After the registration:

#### if you're building a frontend service: 

use our [React component]() to easily check if a connected wallet is a subscribed user or not, and choose to disable some advanced feature based on that.


```typescript
// this code doesn't exist, just demoing

import { useDappscription, SubscriptionModal } from "@dappscription/react"

// using the hook
const { hasValidSub, sub } = useDappscription(connectedAddress, planId)

return (hasValidSub ? <MyAppPage/> : <SubscriptionModal provider={provider}>)
```

#### if you're building helper contracts: 

Use contract call `registry.hasValidSubscription(planId, user)` to check if they're subscribed wallets!

```solidity
(bool hasSub, uint256 _subId) = registry.hasValidSubscription(planId, user);
require(hasSub, "please subscribe!");
```


Dappscription, as a smart contract contract, will not collect any fees, every penny goes to your wallet. You can automatically collect all your "revenue" on our management UI.
### I'm a user

You can use **Dappscription** to manage all your subscriptions to advanced services, make sure you don't pay more than what you're suppose to.

## Getting Started

```shell
forge build
forge test
```