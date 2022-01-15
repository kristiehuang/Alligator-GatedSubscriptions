# Alligator = gated subscription access platform - smart contracts
* anotha kristie toy learning project, this time built from scratch, spec and all
* recurring payments!!!
    * for subscription services; once payment is sent successfully, user automatically receives monthly access NFT for token-gated anything..
        * i.e. user SBAT sets up recurring monthly payment
        * subscription-dependent DAO or community or protocol usage
        * gated libraries
    * or automatic minimum payments on loans
* with expiration, automatic renewal toggle, 

* gater SBAT createNewGate(gateName, monthlySubscriptionCost) -> gateId
* gater SBAT updateSubscriptionCost, updateTotalSubLimit, etc
* gater SBAT deleteGate(gateId)
* user SBAT subscribe(gateId) payable
* user SBAT unsubscribe(gateId)
* events emitted when NewGateCreated, Gate_parameter_Updated, GateDeleted, UserSubscribed, UserUnsubscribed

## on approvals; automatic recurring payments workaround
* can't do automatic recurring payments on blockchian bc user must approve every tx... 
* maybe user can deposit $ into a contract for a year
* and user can withdraw their calculated remaining funds at any time