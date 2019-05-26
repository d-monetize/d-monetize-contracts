// TODO update pragma
pragma solidity ^0.5.2;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract Subscription is Ownable, Pausable {
  event Subscribed(address indexed subscriber);
  event Unsubscribed(address indexed subscriber);
  event BountyUpdated(uint bounty);
  event Charge(address indexed subscriber, uint nextPayment);

  ERC20 public token;
  uint public amount;
  uint public interval;
  uint public bounty;

  mapping(address => uint) public nextPayment;

  constructor(address _token, uint _amount, uint _interval, uint _bounty) public {
    require(_token != address(0), "Token address cannot be 0");
    require(_amount > 0, "Amount must be greater than 0");
    require(_bounty <= _amount, "Bounty must be less than or equal to amount");
    // TODO interval overflow
    require(
      _interval > 0,
      "Payment interval must be greater than 0"
    );

    token = ERC20(_token);
    amount = _amount;
    interval = _interval;
    bounty = _bounty;
  }

  function updateBounty(uint _bounty) public onlyOwner whenNotPaused {
    bount = _bounty;

    emit BountyUpdated(_bounty);
  }

  function isSubscribed(address subscriber) public returns (bool) {
    return nextPayment[subscriber] > 0;
  }

  function subscribe() public whenNotPaused {
    require(!isSubscribed(msg.sender), "Already subscribed");

    nextPayment[msg.sender] = block.timestamp;

    emit Subscribed(msg.sender);
  }

  function unsubscribe() public whenNotPaused {
    require(isSubscribed(msg.sender), "Not subscribed");

    nextPayment[susbcriber] = 0;

    emit Unsubscribed(msg.sender);
  }

  function canCharge(address subscriber) public returns (bool) {
    return (
      !paused() &&
      isSubscribed(subscribger) &&
      block.timestamp >= nextPayment[subscriber] &&
      token.allowance(subscriber, address(this)) >= amount &&
      token.balanceOf(subscriber) >= amount &&
      token.allowance(owner, address(this)) >= bounty
    );
  }

  function charge(address subscriber) public whenNotPaused {
    require(canCharge(subscriber), "Cannot charge");

    // TODO safe math?
    // TODO assert block.timestamp >= nextPayment
    uint delta = (block.timestamp - nextPayment[subscriber]) % interval;
    nextPayment[subscriber] = block.timestamp + (interval - delta);

    require(
      token.transferFrom(subscriber, owner, amount),
      "Failed to transfer tokens from subsciber to owner"
    );

    if (bounty > 0) {
      require(
        token.transferFrom(owner, msg.sender, bounty),
        "Failed to transfer tokens from subsciber to owner"
      );
    }

    emit Charged(subscriber, nextPayment[subscriber]);
  }

  function kill() external onlyOwner {
    selfdestruct(owner);
  }
}
