const { accounts, defaultSender, contract } = require("@openzeppelin/test-environment");
const { constants, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const Ownable = contract.fromArtifact("OwnableMock");

describe("Ownable", function(){
    const [ owner1, owner2, other ] = accounts;

    describe("Constructor", function(){
        it(
            "initializes owner to msg.sender with empty array",
            async function(){
                var ownable = await Ownable.new([]);
                var owners = await ownable.getOwners();
                expect(owners).to.eql([defaultSender]);
            }
        )

        it(
            "initializes owner to given addresses with non-empty array",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var owners = await ownable.getOwners();
                expect(owners).to.eql([owner1, owner2]);
            }
        );
    });

    describe("Check Ownership", function(){
        it(
            "checks existing owner address found in _owners array",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var isOwner = await ownable.checkOwner(owner1);
                expect(isOwner).to.equal(true);
            }
        );

        it(
            "checks non-owner address not found in _owners array",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var isOwner = await ownable.checkOwner(other);
                expect(isOwner).to.equal(false);
            }
        );

        it(
            "finds correct indices of owners",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var indices = [
                    (await ownable.ownerIndex(owner1)).toNumber(),
                    (await ownable.ownerIndex(owner2)).toNumber(),
                ];
                expect(indices).to.eql([0, 1]);
            }
        );

        it(
            "returns -1 if address is not an owner",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var index = (await ownable.ownerIndex(other)).toNumber();

                expect(index).to.equal(-1);
            }
        );
    });

    describe("Add Owner", function(){
        it(
            "adds a new owner",
            async function(){
                var ownable = await Ownable.new([ owner1 ]);
                await ownable.addOwner(owner2, {from: owner1});
                var isOwner = await ownable.checkOwner(owner2);
                expect(isOwner).to.equal(true);
            }
        );

        it(
            "emits event on adding owner",
            async function(){
                var ownable = await Ownable.new([ owner1 ]);
                var receipt = await ownable.addOwner(owner2, {from: owner1});
                expectEvent(
                    receipt,
                    "OwnerAdded",
                    { newOwner: owner2, sender: owner1 }
                );

            }
        );

        it(
            "prevents adding owner that already exists",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                await expectRevert(
                    ownable.addOwner(owner2, {from: owner1}),
                    "Ownable: owner already exists"
                );
            }
        );

        it(
            "prevents non-owners from adding new owners",
            async function(){
                var ownable = await Ownable.new([ owner1 ]);
                await expectRevert(
                    ownable.addOwner(other, {from: other}),
                    "Ownable: caller is not the owner"
                );
            }
        );
    });

    describe("Remove Owner", function(){
        it(
            "removes owner correctly",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var before_remove = await ownable.checkOwner(owner2);
                await ownable.removeOwner(owner2, {from: owner1});
                var after_remove = await ownable.checkOwner(owner2);
                expect([before_remove, after_remove]).to.eql([true, false]);
            }
        );

        it(
            "emits event on removing owner",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var receipt = await ownable.removeOwner(owner2, {from: owner1});
                expectEvent(
                    receipt,
                    "OwnerRemoved",
                    { owner: owner2, sender: owner1 }
                );

            }
        );

        it(
            "prevents non-owner from removing",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                await expectRevert(
                    ownable.removeOwner(owner1, {from: other}),
                    "Ownable: caller is not the owner"
                );
            }
        );

        it(
            "prevents removal when only one owner",
            async function(){
                var ownable = await Ownable.new([ owner1 ]);

                await expectRevert(
                    ownable.removeOwner(owner1, {from: owner1}),
                    "Ownable: cannot remove only owner"
                );
            }
        );

        it(
            "revokes ownership correctly",
            async function(){
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var before_remove = await ownable.checkOwner(owner2);
                await ownable.revokeOwnership({from: owner2});
                var after_remove = await ownable.checkOwner(owner2);
                expect([before_remove, after_remove]).to.eql([true, false]);
            }
        );

    });

    describe("Transfer Ownership", function(){
        it(
            "adds new owner and removes old",
            async function() {
                var ownable = await Ownable.new([ owner1, owner2 ]);
                var before_transfer = await ownable.getOwners();
                await ownable.transferOwnership(other, {from: owner1});
                var after_transfer = await ownable.getOwners();

                expect([before_transfer, after_transfer]).to.eql(
                    [
                        [owner1, owner2],
                        [other, owner2]
                    ]
                );
            }
        );
    });

})