// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract Wakeup {

    // Setting up the different stages
    enum Stages {
        ChallengeFormation,
        ChallengeLockout,
        ChallengeInProgress,
        ChallengeComplete
    }

    // Initialize First stage
    Stages public stage = Stages.ChallengeFormation;

    // Stores the number of times the button click criteria was successful per user
    mapping(address => uint) public successful_clicks;
    // Does this address exist in participants?
    mapping(address => bool) public participantExists;
    // Has this address already clicked during this interval?
    mapping(uint => mapping(address => bool)) public trackingClicks;
    address payable[] public participants_array;
    address payable[] public winners;
    address owner;
    uint public beginning_date; // has to be a date
    uint public end_date; // has to be a date
    uint public numberOfPeriodssOfCompetition;
    uint public currentPeriod = 0;
    uint public startingTime; // has to be a specific second of a 24 period (out of 86400)
    uint public endingTime; // has to be a specific second of a 24 period (out of 86400)
    uint public windowOpenIntoPeriod;
    uint public windowCloseIntoPeriod;
    uint public buyinWei;
    uint public participantLimit;
    uint public period_length; // This is the interval
    bool public rulesEstablished;
    bool public windowOpen = false;

    modifier hasClickedDuringThisIntervalAlready {
        require(trackingClicks[currentPeriod][msg.sender] == false, "You have already clicked the button for today!");
        _;
    }
    modifier atStage(Stages _stage) {
        require(stage == _stage, "Function cannot be called at this time.");
        _;
    }

    modifier isWindowOpen() {
        require(windowOpen == true, "Interval is currently not open.");
        _;
    }

    modifier isParticipant() {
        require(participantExists[msg.sender] == true, "This method is only available for users who have already joined this game.");
        _;
    }
    // Transition to the different stages at the appropriate time
    modifier timedTransitions() {

        // Transitions from the creation of the challenge to lockout exactly 1 period length before
        //TODO: Lockout period is not working as I would expect
        // Contract works despite this though, might not be completely necessary.
        if (stage == Stages.ChallengeFormation && now >= beginning_date + startingTime - period_length) {
            stage = Stages.ChallengeLockout;
        }

        // Transitions from the lockout to the beginning of the challenge and opens the first window of the challenge
        if (stage == Stages.ChallengeLockout && now >= (beginning_date + startingTime)) {
            stage = Stages.ChallengeInProgress;
            windowOpen = true;
        }

        // Keeps track of which day we are in the challenge
        // Technically it should 
        if ((stage == Stages.ChallengeInProgress)) {
            currentPeriod = (now - (beginning_date + startingTime)) / period_length;
        }


        // Opens the window for the current day
        if (stage == Stages.ChallengeInProgress 
            && 
            now >= (beginning_date + startingTime + (period_length*currentPeriod) + windowOpenIntoPeriod) 
            &&
            now <= (beginning_date + startingTime + (period_length*currentPeriod) + windowCloseIntoPeriod)) 
        {
            windowOpen = true;
        } else {
            windowOpen = false;
        }

        // Transitions the challenge to complete after the last day has been closed
        if (stage == Stages.ChallengeInProgress && now >= end_date + endingTime) {
            stage = Stages.ChallengeComplete;
        }
        _;
    }

    // Only owner can call this function
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function establishRules(uint _beginning_date, uint _end_date, uint _startingTime, uint _endingTime, uint _windowOpenIntoPeriod, uint _windowCloseIntoPeriod, uint _period_length, uint _buyInWei, uint _participantLimit) public isOwner timedTransitions atStage(Stages.ChallengeFormation) {
        require(rulesEstablished == false, "The rules have already been set");
        beginning_date = _beginning_date;
        end_date = _end_date;
        startingTime = _startingTime;
        endingTime = _endingTime;
        windowOpenIntoPeriod = _windowOpenIntoPeriod;
        windowCloseIntoPeriod = _windowCloseIntoPeriod;
        period_length = _period_length;
        buyinWei = _buyInWei;
        participantLimit = _participantLimit;
        rulesEstablished = true;
        numberOfPeriodssOfCompetition = (((end_date + endingTime)- (beginning_date + startingTime)) / period_length);
    }

    // Function to join contract
    function joinContract() public payable atStage(Stages.ChallengeFormation) timedTransitions returns (string memory) {
        require(rulesEstablished == true, "The rules need to be set before you can join this contract.");
        require(participants_array.length < participantLimit, "This contract has maxed out participants");
        require(msg.value == buyinWei, "Amount should be equal to the buy-in amount");
        participants_array.push(payable(msg.sender));
        successful_clicks[msg.sender] = 0;
        participantExists[msg.sender] = true;
        return "You have successfully joined the wake up contract";
    } 

    // Confirm whether the user is in the contract as joined or not.
    function verifyJoined(address _participant) public view returns (bool) {
        return participantExists[_participant];
    }

    function wakeUpClick() public timedTransitions atStage(Stages.ChallengeInProgress) isParticipant isWindowOpen hasClickedDuringThisIntervalAlready {
        trackingClicks[currentPeriod][msg.sender] = true;
        successful_clicks[msg.sender] += 1;
    }

    // Highly inefficient, probably a better way to do this
    function payout() public payable timedTransitions isParticipant atStage(Stages.ChallengeComplete) {
        bool found = false;
        uint highestClicks = numberOfPeriodssOfCompetition;
        uint split;
        uint payout_amount;
        // Start from the maximum number of clicks possible and work down
        // If one person is found with highest clicks, see how many people clicked that number
        // Stop looping and finish the payout
        while(!found) {
            for(uint i = 0; i < participants_array.length; i++) {
                if(successful_clicks[participants_array[i]] == highestClicks) {
                    winners.push(participants_array[i]);
                }
            }
            if (winners.length > 0) {
                found = true;
            }
            highestClicks = highestClicks--;
        }
        split = winners.length;
        payout_amount = address(this).balance / split;
        for (uint i = 0; i < winners.length; i++) {
            winners[i].transfer(payout_amount);
        }

    }

}