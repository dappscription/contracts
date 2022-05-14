// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IRegistry.sol";
import "./RegistryNFT.sol";

contract Registry is IRegistry, RegistryNFT, ReentrancyGuard{

    error NotAuthorized();
    error ProjectDoesNotExist();
    error AlreadySubscribed();
    error SubscriptionNotExpired();
    error IllegalRebind();

    using SafeERC20 for IERC20;
    
    ///@dev next plan id
    uint128 public nextPlanId;
    
    ///@dev next subscription id
    uint256 public nextSubId = 1;
    
    ///@dev planId => Plan struct
    mapping(uint128 => IRegistry.Plan) public plans;

    ///@dev token id to subscription detail
    mapping(uint256 => IRegistry.Subscription) public subs ;

    ///@dev planId => user => subscription. Make sure we can easily look-up if a user has existing subscription.
    ///     this mapping might be clear if you transfer nft to an address that already has a sub to the project, and then transfer them out again
    ///     in this case, you can use `rebind` to set the mapping.
    mapping(uint128 => mapping(address => uint256)) planUserMap;

    /// @inheritdoc IRegistry
    function hasValidSubscription(uint128 _planId, address _user) external view returns (bool _valid, uint256 _subId) {
        _subId = planUserMap[_planId][_user];
        if (_subId == 0) return (false, 0);

        uint256 deadline = subs[_subId].validUntil;
        return (deadline > block.timestamp, _subId);
    }

    /// @inheritdoc IRegistry
    function createPlan(
        address _paymentToken,
        address _recipient,
        uint40 _period,
        uint128 _price,
        bool _extentable
    ) external override returns (uint128) {
        uint128 id = nextPlanId;
        plans[id] = IRegistry.Plan({
            owner: msg.sender,
            recipient: _recipient,
            paymentToken: _paymentToken,
            period: _period,
            lastModifiedTimestamp: uint40(block.timestamp),
            price: _price,
            extentable: _extentable
        });

        nextPlanId++;
        emit IRegistry.PlanCreated(id, msg.sender, _paymentToken, _period, _price);
        return id;
    }

    /// @inheritdoc IRegistry
    function subscribe(uint128 _planId, bool _autoRenew) external returns (uint256 subId) {
        IRegistry.Plan memory plan = plans[_planId];
        if (plan.owner == address(0)) revert ProjectDoesNotExist();
        if (planUserMap[_planId][msg.sender] != 0) revert AlreadySubscribed();

        subId = nextSubId;

        // set the mapping
        planUserMap[_planId][msg.sender] = subId;

        uint40 currentTimestamp = uint40(block.timestamp);
        uint40 validUntil = currentTimestamp + plan.period;

        subs[subId] = IRegistry.Subscription({
            planId: _planId,
            lastModifiedTimestamp: currentTimestamp,
            validUntil: validUntil,
            allowAutoRenew: _autoRenew
        });

        nextSubId++;

        // pay the token amount to recipient
        IERC20(plan.paymentToken).safeTransferFrom(msg.sender, plan.recipient, plan.price);

        // mint receipt (NFT to user)
        _mint(msg.sender, subId);

        emit IRegistry.Subscribed(_planId, subId, msg.sender, plan.price, validUntil, _autoRenew);
    }

    /// @inheritdoc IRegistry
    function updateSubscription(uint256 _subId, bool _autoRenew) external {
        if (ownerOf(_subId) != msg.sender) revert NotAuthorized();
        IRegistry.Subscription storage sub = subs[_subId];
        sub.allowAutoRenew = _autoRenew;

        emit IRegistry.SubscriptionUpdated(_subId, _autoRenew);
    }

    /// @inheritdoc IRegistry
    function renew(uint256 _subId) external {
        IRegistry.Subscription memory sub = subs[_subId];
        IRegistry.Plan memory plan = plans[sub.planId];

        uint40 currentTimestamp = uint40 (block.timestamp);
        if (!plan.extentable && currentTimestamp < sub.validUntil) revert SubscriptionNotExpired();
        
        uint40 newValidUntil = currentTimestamp > sub.validUntil 
            ? currentTimestamp + plan.period 
            : sub.validUntil + plan.period; 
        
        subs[_subId].lastModifiedTimestamp = currentTimestamp;
        subs[_subId].validUntil = newValidUntil;

        // pay from msg.sender to to recipient
        IERC20(plan.paymentToken).safeTransferFrom(msg.sender, plan.recipient, plan.price);

        emit IRegistry.SubscriptionRenewed(_subId, msg.sender, plan.price, newValidUntil);
    }

    ///@dev overriding transferFrom to update `planUserMap` mapping.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.transferFrom(from, to, id);
        IRegistry.Subscription memory sub = subs[id];
        if(planUserMap[sub.planId][to] != 0) revert AlreadySubscribed();
        delete planUserMap[sub.planId][from];
        planUserMap[sub.planId][to] = id;
    }   
}
