// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Alligator 🐊 - Gated Subscriptions
/// @author Kristie Huang
contract Alligator {

    /// @param gater Creator & manager of gate
    struct Gate {
		uint256 gateId;
		address gater;
        string gateName;
		uint256 monthlySubscriptionCostInWei;
        uint256 totalSubLimit;
        // ERC721 accessTokenContract;
	}

    constructor() {}

    /*///////////////////////////////////////////////////////////////
                      EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewGateCreated();
    event GateSubscriptionCostUpdated();
    event GateTotalSubLimitUpdated();
    event GateDeleted();
    event UserSubscribed();
    event UserUnsubscribed();

    /*///////////////////////////////////////////////////////////////
                      GATER (gator 🐊 heh) FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    modifier gaterOnly() {
        // todo: require
        _;
    }

    function createNewGate(string gateName, uint256 monthlySubscriptionCostInWei) public returns (uint256) {
        // add msg.sender to gaters
    }

    function updateGateSubscriptionCost(uint256 newMonthlySubCostInWei) gaterOnly public {

    } 
    
    function updateGateTotalSubLimit() gaterOnly public {

    } 
    
    function deleteGate(uint256 gateId) gaterOnly public {

    }

    /*///////////////////////////////////////////////////////////////
                      USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function subscribe(uint256 gateId) public payable {

    }

    function unsubscribe(uint256 gateId) public {
        
    }

    /*///////////////////////////////////////////////////////////////
                      HELPER / UTIL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getGateInfo(uint256 gateId) view public {
        
    }
    
}