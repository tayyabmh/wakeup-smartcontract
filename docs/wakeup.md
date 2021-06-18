# WakeUp Smart Contract
This smart contract allows participants to play a game of accountability to wake up during a certain time.

## Basic Game Play
1. Challenge Formation
    - This is the intial stage of the contract where the rules are being established
    - Rules being established are: First day of game, Last day of game (can be same as first day if 1 day of competition), Time when contract starts, Time when contract ends, When the window opens, when the window closes, buyin, and max number of participants
2. Challenge Lockout
    - Locks the contract out so that no one can join or change the rules anymore
3. Challenge In Progress
    - Game is being played
4. Challenge Complete
    - The challenge is over and now needs to pay out the winners


## Usage

### Establish the rules
*Set the rules of the contract: when it starts, when it ends, Wakeup window, buyin amount, max participants*
*Can only be called by the owner of the contract during the Challenge Formation phase*
```solidity
    function establishedRules(uint _beginning_date, uint _end_date, uint _startingTime, uint _endingTime, uint _windowOpenIntoPeriod, uint _windowCloseIntoPeriod, uint period_length, uint _buyInWei, uint _participantLimit)
    _beginning date = In Unix Timestamp (ex. June 17 00:00:00, midnight)
    _end_date = In Unix Timestamp (ex. June 21 00:00:00, midnight)
    _startingTime = In Unix Timestamp (5:00 AM = 5 hours * 3600 seconds per hour)
    _endingTime = In Unix Timestamp (6:00 AM = 6 hours * 3600 seconds per hour)
    _windowOpenIntoPeriod = default should be 0, but can play with this. (Ex. The window opens this many seconds into the period after startTime)
    _windowCloseIntoPeriod = length of period essentially
    _period_length = default should be 86400 for seconds in a day, but can play with this for testing
    _buyin = Wei denominated buy-in to participate
    _participantlimit = What are the maximum number of participants?
```

### Join Contract
*There is maximum number of participants, but anyone can join who puts the buy-in amount*
*Can only be called during the Challenge Formation phase*
*Contract owner is not automatically joined*
```solidity
    function joinContract() payable
```

### Wake Up CLick
*Used for particpants to play the game and click during the window period. This is only open during the Challenge In Progress phase. Only joined participants can click.*
**Only one click is allowed per interval**
```solidity
    function wakeUpClick()
```

### Payout
*Only Challenge Complete Phase*
*Pays the user(s) with the highest amount of clicks during the challenge. If there are multiple winners then it splits the pot against those winners.*
*Anyone can call this function*
```solidity
    function payout()
```