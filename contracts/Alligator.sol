// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Alligator 🐊 - Gated Subscriptions
/// @author Kristie Huang
// TODO: eventually refactor into AlligatorFactory.sol (to deploy new gates & manage permissions) & AlligatorGate.sol (user functionality for a gate)
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

    /// @dev Index counter for gateIds
    uint256 public gateIdCounter;

    /// @dev Maps gaters to gateIds they manage
    mapping(address => uint256[]) public gaterToGateIds;

    /// @dev Maps gateIds to gates
    mapping(uint256 => Gate) public gateIdToGate;

    constructor() {
        gateIdCounter = 1;
    }

    /*///////////////////////////////////////////////////////////////
                      EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewGateCreated(Gate newGate);
    event GateSubscriptionCostUpdated();
    event GateTotalSubLimitUpdated();
    event GateDeleted();
    event UserSubscribed();
    event UserUnsubscribed();

    /*///////////////////////////////////////////////////////////////
                      GATER (gator 🐊 heh) FUNCTIONS
    //////////////////////////////////////////////////////////////*/


    // TODO: learn about visibility best practices; about memory/callback...
    // QUESTION: no need for SafeMath after solidity 0.8 right???? check this for all math/incremeents/etc


    modifier gaterOnly() {
        // todo: require
        _;
    }

    function createNewGate(string memory gateName, uint256 monthlySubscriptionCostInWei, uint256 totalSubLimit) public payable returns (uint256 gateid) {
        // TODO: payable?? is it free to create Gate? Or how does Alligator make $? Figure out fee scheme later

        // checks: is it okay to create gates with same name?
        // monthlySubscriptionCostInWei can be free? yes
        require(totalSubLimit > 0, "Cannot limit gate at 0 subscribers!");

        uint256 gateId = gateIdCounter;
        Gate memory gate = Gate({
            gateId: gateId,
            gater: msg.sender,
            gateName: gateName,
            monthlySubscriptionCostInWei: monthlySubscriptionCostInWei,
            totalSubLimit: totalSubLimit
            // accessTokenContract
		});

        gaterToGateIds[msg.sender].push(gateId);
        gateIdToGate[gateId] = gate;

        gateIdCounter++; // Increment gateIdCounter for future gates

        emit NewGateCreated(gate);
        return gateId;
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

    /// @notice Subscribe to a gateId! 
    /// @dev User deposits enough to prepay for a yr, but user can withdraw unused funds at anytime
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