// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IRegistry.sol";
import "./RegistryNFT.sol";

contract Registry is IRegistry, RegistryNFT, ReentrancyGuard{

    error ProjectDoesNotExist();
    error AlreadySubscribed();

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
    mapping(uint128 => mapping(address => uint256)) projectUserMap;

    /// @inheritdoc IRegistry
    function hasValidSubscription(uint128 _planId, address _user) external view returns (bool _valid, uint256 _subId) {
        _subId = projectUserMap[_planId][_user];
        if (_subId == 0) return (false, 0);

        uint256 deadline = subs[_subId].validUntil;
        return (deadline > block.timestamp, _subId);
    }

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
        if (projectUserMap[_planId][msg.sender] != 0) revert AlreadySubscribed();

        tokenId = nextSubId;

        // set the mapping
        projectUserMap[_planId][msg.sender] = tokenId;

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
