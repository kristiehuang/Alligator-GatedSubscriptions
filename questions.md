

    
Things to figure out re: functionality
* is it free to create Gate? Or how does Alligator make $? Figure out fee scheme later
* is it okay to create gates with same name?
* IS SUBSCRIPTION CONTINUOUS & PRORATED?? OR BY THE MONTH??; 
    * figure out how much $ to return on unsubscribe
    * AFTER FUNDS DEPOSITED from new subscriber, WHO GETS TO WITHDRAW FUNDS?...
      
      
        // FIXME: .LENGTH IS INACCURATE IF ELEMENTS HAVE BEEN RESET
        // looping thru is baddd cuz this array could grow to infinite size
        for (uint i = 0; i < gaterToGateIds[msg.sender].length; i++) {
            if (gaterToGateIds[msg.sender][i].gateId == gateId) {
                delete gaterToGateIds[msg.sender][i];
            }
        }

        
        // TODO: AFTER FUNDS DEPOSITED from new subscriber, WHO GETS TO WITHDRAW FUNDS?.... 
        // can only withdraw funds for users who have finished their subscription year OR finished months. Otherwise that money cannot be touched

        // TODO: for each gate, track $ that has been finished & can be withdrawn.


    // QUESTION: IS SUBSCRIPTION CONTINUOUS & PRORATED?? OR BY THE MONTH??
        // todo: figure out how much $ to return


