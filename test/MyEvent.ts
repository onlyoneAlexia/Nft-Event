import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { EventNft } from "../typechain-types";
import { EventRegistration } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Event System", function () {
  let eventNft: EventNft;
  let eventRegistration: EventRegistration;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let startTime: number;
  let endTime: number;

  async function deployEventFixture() {
    [owner, addr1, addr2] = await ethers.getSigners();

    const EventNftFactory = await ethers.getContractFactory("EventNft");
    eventNft = await EventNftFactory.deploy() as EventNft;
    await eventNft.waitForDeployment();

    const EventRegistrationFactory = await ethers.getContractFactory("EventRegistration");
    eventRegistration = await EventRegistrationFactory.deploy() as EventRegistration;
    await eventRegistration.waitForDeployment();

    startTime = Math.floor(Date.now() / 1000) + 3600;
    endTime = startTime + 36000;

    return { eventNft, eventRegistration, owner, addr1, addr2, startTime, endTime };
  }

  beforeEach(async function () {
    const fixture = await loadFixture(deployEventFixture);
    eventNft = fixture.eventNft;
    eventRegistration = fixture.eventRegistration;
    owner = fixture.owner;
    addr1 = fixture.addr1;
    addr2 = fixture.addr2;
    startTime = fixture.startTime;
    endTime = fixture.endTime;

    await eventRegistration.createEvent("Test Event", startTime, endTime, await eventNft.getAddress());
    await eventNft.mint(addr1.address, 1);
    await eventNft.mint(addr1.address, 2);
    await eventNft.mint(addr2.address, 3);
  });

  it("Should allow minting of NFTs", async function () {
    expect(await eventNft.ownerOf(1)).to.equal(addr1.address);
  });

  it("Should create an event", async function () {
    const event = await eventRegistration.getEventDetails(1);
    expect(event.name).to.equal("Test Event");
    expect(event.startTime).to.equal(startTime);
    expect(event.endTime).to.equal(endTime);
    expect(event.nftAddress).to.equal(await eventNft.getAddress());
    expect(event.owner).to.equal(owner.address);
  });

  it("Should fail to create an event with invalid time range", async function () {
    await expect(eventRegistration.createEvent("Invalid Event", endTime, startTime, await eventNft.getAddress()))
      .to.be.revertedWith("Invalid time range");
  });

  it("Should allow registration with owned NFT", async function () {
    // Check event details and log them out
    const eventDetails = await eventRegistration.getEventDetails(1);
    console.log("Event Details:");
    console.log("Name:", eventDetails.name);
    console.log("Start Time:", eventDetails.startTime.toString());
    console.log("End Time:", eventDetails.endTime.toString());
    console.log("NFT Address:", eventDetails.nftAddress);
    console.log("Owner:", eventDetails.owner);
    //log out current time 
    console.log("Current Time:", Math.floor(Date.now() / 1000));
    await expect(eventRegistration.connect(addr1).registerForEvent(1, 1))
      .to.emit(eventRegistration, "ParticipantRegistered")
      .withArgs(1, addr1.address, 1);

    // The registration event emission is already checked in the previous expect statement,
    // so no additional checks are necessary here.
  });

  it("Should not allow registration with unowned NFT", async function () {
    await expect(eventRegistration.connect(addr1).registerForEvent(1, 3))
      .to.be.revertedWith("Must own the specified NFT");
  });
});