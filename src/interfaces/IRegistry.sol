// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IRegistry {
  event PlanCreated(uint128 planId, address owner, address token, uint40 period, uint128 price);

  event Subscribed(uint128 planId, uint256 subscriptionId, address subscriber, uint128 price, uint40 validUntil, bool allowAutoRenew);

  event SubscriptionUpdated(uint256 subscriptionId, bool allowAutoRenew);

  event SubscriptionRenewed(uint256 subscriptionId, address payer, uint128 price, uint40 validUntil);

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
    /// @notice can people extend the subscription before expiration
    bool extentable;
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

  /// @notice return true if an user address has a valid subscription to a planId
  function hasValidSubscription(uint128 _planId, address _user) external returns (bool _valid, uint256 _subId);

  /// @notice create a new plan 
  function createPlan(address _paymentToken, address _recipient, uint40 _period, uint128 _price, bool _extentable) external returns (uint128 planId);

  // /// @notice update the plan detail. This will not affect existing users.
  // function updatePlan() external;

  /// @notice pay the token, and recive a new subscription NFT.
  function subscribe(uint128 _planId, bool _autoRenew) external returns (uint256 tokenId);

  /// @notice extend the subscription after expired.
  /// @param _subId subscription id
  function renew(uint256 _subId) external;

  // /// @notice user can update auto renew preference. Disabling it is consiered "unsubscribed".
  function updateSubscription(uint256 _subId, bool _autoRenew) external;

  // /// @dev renew a subscription for a user.
  // function renewFor(address _user, uint128 _planId) external;


}
