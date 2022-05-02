// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "../interfaces/IRegistry.sol";

contract Registry is IRegistry{
    
    uint128 public nextPlanId;
    
    uint256 public nextSubscriptionId;
    
    ///@dev planId => Plan struct
    mapping(uint128 => IRegistry.Plan) public plans;

    ///@dev subscriptions
    mapping(uint256 => IRegistry.Subscription) public subs ;

    function createPlan(
        address _paymentToken,
        address _recipient,
        uint40 _period,
        uint128 _price
    ) external override returns (uint128) {
        uint128 id = nextPlanId;
        plans[id] = IRegistry.Plan({
            owner: msg.sender,
            recipient: _recipient,
            paymentToken: _paymentToken,
            period: _period,
            lastModifiedTimestamp: uint40(block.timestamp),
            price: _price
        });

        nextPlanId++;
        emit IRegistry.PlanCreated(id, msg.sender, _paymentToken, _period, _price);
        return id;
    }
}
