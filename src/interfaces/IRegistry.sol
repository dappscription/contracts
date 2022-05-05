// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IRegistry {

  error Subscription_Ongoing();

  event PlanCreated(uint256 id, address owner, address token, uint40 period, uint128 price);

  event Subscribed(uint256 planId, uint256 subscriptionId, address subscriber, uint40 validUntil, bool allowAutoRenew);

  ///@dev any projects can register new plans for people to subscribe
  struct Plan {
    /// @notice owner that's allow to update plan details
    address owner;
    /// @notice payment recipient
    address recipient;
    /// @notice ERC20 token address used as payment token
    address paymentToken;
    /// @notice how long the plan will be enabled for each payment.
    uint40 period;
    /// @notice last time the plan is modified
    uint40 lastModifiedTimestamp;
    /// @notice price for 1 period, denomicated in paymentToken
    uint128 price;
  }

  /// @notice each 'subscription' is stored as ERC721 that can be transferable to new addresses.
  struct Subscription {
    /// @notice unique id match to a plan.
    uint128 planId;
    /// @notice last time the plan is modified
    uint40 lastModifiedTimestamp;
    /// @notice until when the plan is valid
    uint40 validUntil;
    /// @notice is the user want to allow auto-renew. This would enable plan owners to automatically reneww a user subscription
    bool allowAutoRenew;
  }

  /// @notice create a new plan 
  function createPlan(address _paymentToken, address _recipient, uint40 _period, uint128 _price) external returns (uint128 planId);

  // /// @notice update the plan detail. This will not affect existing users.
  // function updatePlan() external;

  /// @notice pay the token, and recive a new subscription NFT.
  function subscribe(uint128 _planId, bool _autoRenew) external returns (uint256 tokenId);

  // /// @notice user can update auto renew preference. Disabling it is consiered "unsubscribed".
  // function updateSubscription(uint128 _planId, bool _autoRenew) external returns (uint256 tokenId);

  // /// @dev renew a subscription for a user.
  // function renewFor(address _user, uint128 _planId) external;


}
