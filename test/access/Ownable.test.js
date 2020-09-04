const { accounts, defaultSender, contract } = require("@openzeppelin/test-environment");
const { constants, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

const Ownable = contract.fromArtifact("OwnableMock");

describe("Ownable", function(){
    const [ owner1, owner2, other ] = accounts;

    it(
        "empty array initializes owner to msg.sender",
        async function(){
            var ownable = await Ownable.new([]);
            var owners = await ownable.getOwners();
            expect(owners).to.eql([defaultSender]);
        }
    )

    it(
        "non-empty array of owners assigned correctly",
        async function(){
            var ownable = await Ownable.new([ owner1, owner2 ]);
            var owners = await ownable.getOwners();
            expect(owners).to.eql([owner1, owner2]);
        }
    );

    it(
        "check existing owner address found in _owners array",
        async function(){
            var ownable = await Ownable.new([ owner1, owner2 ]);
            var isOwner = await ownable.checkOwner(owner1);
            expect(isOwner).to.equal(true);
        }
    )

    it(
        "check non-owner address not found in _owners array",
        async function(){
            var ownable = await Ownable.new([ owner1, owner2 ]);
            var isOwner = await ownable.checkOwner(other);
            expect(isOwner).to.equal(false);
        }
    )



})