// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IRegistry.sol";
import "./RegistryNFT.sol";

contract Registry is IRegistry, RegistryNFT, ReentrancyGuard{

    error ProjectDoesNotExist();

    using SafeERC20 for IERC20;
    
    ///@dev next plan id
    uint128 public nextPlanId;
    
    ///@dev next subscription id
    uint256 public nextSubId;
    
    ///@dev planId => Plan struct
    mapping(uint128 => IRegistry.Plan) public plans;

    ///@dev subscriptions
    mapping(uint256 => IRegistry.Subscription) public subs ;

    /// @inheritdoc IRegistry
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

    /// @inheritdoc IRegistry
    function subscribe(uint128 _planId, bool _autoRenew) external returns (uint256 tokenId) {
        IRegistry.Plan memory plan = plans[_planId];
        if (plan.owner == address(0)) revert ProjectDoesNotExist();
        tokenId = nextSubId;

        uint40 currentTimestamp = uint40(block.timestamp);
        uint40 validUntil = currentTimestamp + plan.period;

        subs[tokenId] = IRegistry.Subscription({
            planId: _planId,
            lastModifiedTimestamp: currentTimestamp,
            validUntil: validUntil,
            allowAutoRenew: _autoRenew
        });

        nextSubId++;

        // pay the token amount to owner
        IERC20(plan.paymentToken).safeTransferFrom(msg.sender, plan.recipient, plan.price);

        // mint receipt (NFT to user)
        _mint(msg.sender, tokenId);

        emit IRegistry.Subscribed(_planId, tokenId, msg.sender, validUntil, _autoRenew);
    }
}
