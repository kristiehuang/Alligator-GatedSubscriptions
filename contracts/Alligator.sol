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

    /// @dev Maps gateIds to gates
    mapping(uint256 => Gate) public gateIdToGate;

    /// @dev Maps gaters to gateIds they manage
    mapping(address => uint256[]) public gaterToGateIds;


    /// @dev Maps users to gates they subscribe to & date of subscription; i.e. 0x1234 -> gateId123 -> Jan 1
    mapping(address => mapping(uint256 => uint256)) public userSubscriptions;

    constructor() {
        gateIdCounter = 1;
    }

    /*///////////////////////////////////////////////////////////////
                      EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewGateCreated(Gate newGate);
    event GateSubscriptionCostUpdated(uint256 gateId, uint256 newMonthlySubCostInWei);
    event GateTotalSubLimitUpdated(uint256 gateId, uint256 totalSubLimit);
    event GateDeleted(uint256 gateId);
    event UserSubscribed(address user, uint256 gateId);
    event UserUnsubscribed(address user, uint256 gateId);

    /*///////////////////////////////////////////////////////////////
                      GATER (gator 🐊 heh) FUNCTIONS
    //////////////////////////////////////////////////////////////*/


    // TODO: learn about visibility best practices; 
    // QUESTION: about memory/callback...
        // We can pass an array as a function argument in solidity, the function visibility determines if the keyword before the array name should be calldata or memory. We use calldata if the function visibility is external and memory if the function visibility is public and internal. See example below:
    // QUESTION: no need for SafeMath after solidity 0.8 right???? check this for all math/incremeents/etc
    // TODO: do i need to use uint256 for everything or can i use like uint128 etc
    // TODO: require vs assert vs revert https://consensys.net/blog/developers/solidity-best-practices-for-smart-contract-security/

    modifier gaterOnly(uint256 gateId) {
        require(gateIdToGate[gateId].exists, "This gateId does not exist");
        require(gateIdToGate[gateId].gater == msg.sender, "Gater must have permission to manage this gate!");
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

    function updateGateSubscriptionCost(uint256 gateId, uint256 newMonthlySubCostInWei) gaterOnly(gateId) public {
        gateIdToGate[gateId].monthlySubscriptionCostInWei = newMonthlySubCostInWei;
        emit GateSubscriptionCostUpdated(gateId, newMonthlySubCostInWei);
    } 
    
    function updateGateTotalSubLimit(uint256 gateId, uint256 totalSubLimit) gaterOnly(gateId) public {
        require(totalSubLimit > 0, "Cannot limit gate at 0 subscribers!");

        gateIdToGate[gateId].totalSubLimit = totalSubLimit;
        emit GateTotalSubLimitUpdated(gateId, totalSubLimit);
    } 
    
    function deleteGate(uint256 gateId) gaterOnly(gateId) public {        
        // Remove gateId from gaterToGateIds[msg.sender] array
        // FIXME: .LENGTH IS INACCURATE IF ELEMENTS HAVE BEEN RESET
        // looping thru is baddd cuz this array could grow to infinite size
        for (uint i = 0; i < gaterToGateIds[msg.sender].length; i++) {
            if (gaterToGateIds[msg.sender][i].gateId == gateId) {
                delete gaterToGateIds[msg.sender][i];
            }
        }

        // Remove gate from gateIdToGate array
        delete gateIdToGate[gateId];

        emit GateDeleted(gateId);
    }

    /*///////////////////////////////////////////////////////////////
                      USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Subscribe to a gateId! 
    /// @dev User deposits enough to prepay for a yr, but user can withdraw unused funds at anytime
    function subscribe(uint256 gateId) public payable {
        require(gateIdToGate[gateId].exists, "This gateId does not exist");
        require(gateId not in userSubscriptions[msg.sender], "User is already subscribed to this gate!");

        Gate memory gate = gateIdToGate[gateId];
        // QUESTION: is msg.value in wei? or eth or gwei or what
        require(gate.monthlySubscriptionCostInWei * 12 == msg.value, "User must deposit enough to prepay for a year");

        userSubscriptions[msg.sender][gateId] = block.timestamp;
        // TODO: AFTER FUNDS DEPOSITED, WHO GETS TO WITHDRAW FUNDS?.... 
        // can only withdraw funds for users who have finished their subscription year OR finished months. Otherwise that money cannot be touched
        // TODO: for each gate, track $ that has been finished & can be withdrawn.

        emit UserSubscribed(msg.sender, gateId);
    }

    // QUESTION: IS SUBSCRIPTION CONTINUOUS & PRORATED?? OR BY THE MONTH??

    /// @notice Unsubscribe to a gateId; return prorated unused funds if subscription year is not up
    function unsubscribe(uint256 gateId) public {
        require(gateIdToGate[gateId].exists, "This gateId does not exist");
        require(userSubscriptions[msg.sender][gateId].exists, "User is not subscribed to this gate");
        
        uint256 timeRemaining = getTimeRemainingInUserSubscription(msg.sender, gateId);
        // todo: figure out how much $ to return
        // todo: transfer back money to msg.sender 

        delete userSubscriptions[msg.sender][gateId];
        emit UserUnsubscribed(msg.sender, gateId);
    }

    /*///////////////////////////////////////////////////////////////
                      HELPER / UTIL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // QUESTION: do i need these if the mappings are public? Can directly query from the mappings instead of needing getter fxn
    
    function getGateInfo(uint256 gateId) view public returns (Gate memory gate) {
        // TODO: if !gateIdToGate[gateId].exists , return null / empty, error msg! or Require ??
        return gateIdToGate[gateId];
    }

    function getGatesManagedBy(address gater) view public returns (uint256[] memory gatesManaged) {
        return gaterToGateIds[gater];
    }

    function getTimeRemainingInUserSubscription(address user, uint256 gateId) public returns (uint) {
        require(userSubscriptions[msg.sender][gateId].exists, "User is not subscribed to this gate");

        uint subscriptionTime = userSubscriptions[msg.sender][gateId];
        return block.timestamp - subscriptionTime;
    }
    
}