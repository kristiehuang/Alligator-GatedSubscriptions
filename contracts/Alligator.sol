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
        uint256 maxSubs;
        uint256 currentSubs;
        // ERC721 accessTokenContract;
    }

    struct Subscription {
        uint256 subscriptionId;
        uint256 gateId;
        address subscriber;
        uint256 startDate;
        bool active;
    }

    /// @dev Index counter for gateIds
    uint256 public gateIdCounter;

    /// @dev Maps gateIds to gates
    mapping(uint256 => Gate) public gates;

    /// @dev Maps subscriptionIds to subscriptions
    mapping(uint256 => Subscription) public subscriptions;

    /// @dev Maps gaters to gateIds they manage
    mapping(address => uint256[]) public gaterToGateIds;

    /// @dev Maps users to subscriptions; i.e. 0x1234 -> subscriptionId
    mapping(address => uint256) public userSubscriptions;

    constructor() {
        gateIdCounter = 1;
    }

    /*///////////////////////////////////////////////////////////////
                      EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewGateCreated(Gate newGate);
    event GateSubscriptionCostUpdated(
        uint256 gateId,
        uint256 newMonthlySubCostInWei
    );
    event GateMaxSubsUpdated(uint256 gateId, uint256 maxSubs);
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
        require(gates[gateId].exists, "This gateId does not exist");
        require(
            gates[gateId].gater == msg.sender,
            "Gater must have permission to manage this gate!"
        );
        _;
    }

    function createNewGate(
        string memory gateName,
        uint256 monthlySubscriptionCostInWei,
        uint256 maxSubs
    ) public payable returns (uint256 gateid) {
        // TODO: payable?? is it free to create Gate? Or how does Alligator make $? Figure out fee scheme later

        // monthlySubscriptionCostInWei can be free? yes
        require(maxSubs > 0, "Cannot limit gate at 0 subscribers!");

        uint256 gateId = gateIdCounter;
        Gate memory gate = Gate({
            gateId: gateId,
            gater: msg.sender,
            gateName: gateName,
            monthlySubscriptionCostInWei: monthlySubscriptionCostInWei,
            maxSubs: maxSubs,
            currentSubs: 0
            // accessTokenContract
        });

        gaterToGateIds[msg.sender].push(gateId);
        gates[gateId] = gate;

        gateIdCounter++; // Increment gateIdCounter for future gates

        emit NewGateCreated(gate);
        return gateId;
    }

    function updateGateSubscriptionCost(
        uint256 gateId,
        uint256 newMonthlySubCostInWei
    ) public gaterOnly(gateId) {
        gates[gateId].monthlySubscriptionCostInWei = newMonthlySubCostInWei;
        emit GateSubscriptionCostUpdated(gateId, newMonthlySubCostInWei);
    }

    function updateGateMaxSubs(uint256 gateId, uint256 maxSubs)
        public
        gaterOnly(gateId)
    {
        require(maxSubs > 0, "Cannot limit gate at 0 subscribers!");

        gates[gateId].maxSubs = maxSubs;
        emit GateMaxSubsUpdated(gateId, maxSubs);
    }

    function deleteGate(uint256 gateId) public gaterOnly(gateId) {
        // Remove gateId from gaterToGateIds[msg.sender] array
        // FIXME: .LENGTH IS INACCURATE IF ELEMENTS HAVE BEEN RESET
        // looping thru is baddd cuz this array could grow to infinite size
        for (uint256 i = 0; i < gaterToGateIds[msg.sender].length; i++) {
            if (gaterToGateIds[msg.sender][i].gateId == gateId) {
                delete gaterToGateIds[msg.sender][i];
            }
        }

        // Remove gate from gates array
        delete gates[gateId];

        emit GateDeleted(gateId);
    }

    /*///////////////////////////////////////////////////////////////
                      USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Subscribe to a gateId!
    /// @dev User deposits enough to prepay for a yr, but user can withdraw unused funds at anytime
    function subscribe(uint256 gateId) public payable {
        require(gates[gateId].exists, "This gateId does not exist");
        require(
            userSubscriptions[msg.sender].get(gateId).active,
            "User is already subscribed to this gate!"
        );

        Gate memory gate = gates[gateId];
        // QUESTION: is msg.value in wei? or eth or gwei or what
        require(
            gate.monthlySubscriptionCostInWei * 12 == msg.value,
            "User must deposit enough to prepay for a year"
        );

        uint256 subscriptionId = gate.currentSubs;

        Subscription memory sub = Subscription({
            subscriptionId: subscriptionId,
            startDate: block.timestamp,
            gateId: gateId,
            subscriber: msg.sender,
            active: true
        });

        userSubscriptions[msg.sender] = subscriptionId;
        gate.currentSubs++;

        // TODO: AFTER FUNDS DEPOSITED, WHO GETS TO WITHDRAW FUNDS?....
        // can only withdraw funds for users who have finished their subscription year OR finished months... including users who have unsubscribed already. Otherwise that money cannot be touched
        // TODO: for each gate, track $ that has been finished & can be withdrawn.

        emit UserSubscribed(msg.sender, gateId);
    }

    // QUESTION: IS SUBSCRIPTION CONTINUOUS & PRORATED?? OR BY THE MONTH??

    /// @notice Unsubscribe to a gateId; return prorated unused funds if subscription year is not up
    function unsubscribe(uint256 gateId) public {
        require(gates[gateId].exists, "This gateId does not exist");
        require(
            userSubscriptions[msg.sender][gateId].exists,
            "User is not subscribed to this gate"
        );

        uint256 timeRemaining = getTimeRemainingInUserSubscription(
            msg.sender,
            gateId
        );
        // if timeRemaining <= 0, user is automatically unsubscribed... no need to act
        // track $ that has alrady been finished
        // todo: figure out how much $ to return
        // todo: transfer back money to msg.sender

        delete userSubscriptions[msg.sender][gateId];
        emit UserUnsubscribed(msg.sender, gateId);
    }

    /*///////////////////////////////////////////////////////////////
                      HELPER / UTIL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // QUESTION: do i need these if the mappings are public? Can directly query from the mappings instead of needing getter fxn

    function getGateInfo(uint256 gateId)
        public
        view
        returns (Gate memory gate)
    {
        // TODO: if !gates[gateId].exists , return null / empty, error msg! or Require ??
        return gates[gateId];
    }

    function getGatesManagedBy(address gater)
        public
        view
        returns (uint256[] memory gatesManaged)
    {
        return gaterToGateIds[gater];
    }

    function getTimeRemainingInUserSubscription(address user, uint256 gateId)
        public
        returns (uint256)
    {
        require(
            userSubscriptions[msg.sender][gateId].exists,
            "User is not subscribed to this gate"
        );

        uint256 subscriptionTime = userSubscriptions[msg.sender][gateId];
        return block.timestamp - subscriptionTime;
    }

    function isUserSubscriptionExpired(address user, uint256 gateId)
        public
        returns (uint256)
    {
        return getTimeRemainingInUserSubscription(user, gateId) <= 0;
    }
}
