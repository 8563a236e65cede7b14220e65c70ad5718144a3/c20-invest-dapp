const { accounts, defaultSender, contract } = require("@openzeppelin/test-environment");
const { constants, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const Suspendable = contract.fromArtifact("SuspendableMock");

describe("Suspendable", function(){

    beforeEach(async function(){
        this.suspendable = await Suspendable.new();
    });

    describe("Constructor", function(){
        it(
            "should successfully deploy contract",
            async function(){
                var state = (await this.suspendable.getState.call()).toNumber();
                expect(state).to.be.equal(0);
            }
        );
    });

    describe("Suspension functionality", function(){
        it(
            "should suspend contract",
            async function(){
                await this.suspendable.suspend();
                var state = (await this.suspendable.getState.call()).toNumber();
                expect(state).to.be.equal(1);
            }
        );

        it(
            "should resume contract",
            async function(){
                await this.suspendable.suspend();
                await this.suspendable.resume();
                var state = (await this.suspendable.getState.call()).toNumber();
                expect(state).to.be.equal(0);
            }
        );
    });

    describe("Modifiers", function(){
        it(
            "should not call an onlySuspended function while active",
            async function(){
                await expectRevert(
                    this.suspendable.resume(),
                    "Suspendable: function only available while contract suspended"
                )
            }
        );

        it(
            "should not call an onlyActive function while suspended",
            async function(){
                await this.suspendable.suspend();
                await expectRevert(
                    this.suspendable.suspend(),
                    "Suspendable: function only available while contract active"
                )
            }
        );
    });

    describe("Events", function(){
        it(
            "should emit Suspended event",
            async function(){
                var receipt = await this.suspendable.suspend();
                expectEvent(
                    receipt,
                    "Suspended",
                    { account: defaultSender}
                );
            }
        );

        it(
            "should emit Resumed event",
            async function(){
                await this.suspendable.suspend();
                var receipt = await this.suspendable.resume();
                expectEvent(
                    receipt,
                    "Resumed",
                    { account: defaultSender}
                );
            }
        );
    });

});