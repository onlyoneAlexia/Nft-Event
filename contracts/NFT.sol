// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract EventRegistration {
    struct Event {
        string name;
        uint256 startTime;
        uint256 endTime;
        address nftAddress;
        address owner;
        mapping(address => uint256) registeredParticipants; // Maps participant address to NFT ID
        mapping(uint256 => bool) usedNftIds; // Tracks used NFT IDs
    }

    mapping(uint256 => Event) public events;
    uint256 public eventCount;

    event EventCreated(uint256 indexed eventId, string name, address owner);
    event ParticipantRegistered(uint256 indexed eventId, address participant, uint256 nftId);
    event ParticipantDeregistered(uint256 indexed eventId, address participant, uint256 nftId);

    function createEvent(string memory _name, uint256 _startTime, uint256 _endTime, address _nftAddress) external {
        require(_startTime < _endTime, "Invalid time range");
        require(_nftAddress != address(0), "Invalid NFT address");

        eventCount++;
        Event storage newEvent = events[eventCount];
        newEvent.name = _name;
        newEvent.startTime = _startTime;
        newEvent.endTime = _endTime;
        newEvent.nftAddress = _nftAddress;
        newEvent.owner = msg.sender;

        emit EventCreated(eventCount, _name, msg.sender);
    }

    function registerForEvent(uint256 _eventId, uint256 _nftId) external {
        Event storage event_ = events[_eventId];
        require(event_.startTime > 0, "Event does not exist");
        //TO-DEBUG
       // require(block.timestamp <= event_.endTime, "Event has ended");
        require(event_.registeredParticipants[msg.sender] == 0, "Already registered");
        require(!event_.usedNftIds[_nftId], "NFT ID already used");

        IERC721 nft = IERC721(event_.nftAddress);
        require(nft.ownerOf(_nftId) == msg.sender, "Must own the specified NFT");

        event_.registeredParticipants[msg.sender] = _nftId;
        event_.usedNftIds[_nftId] = true;
        emit ParticipantRegistered(_eventId, msg.sender, _nftId);
    }

    function deregisterFromEvent(uint256 _eventId) external {
        Event storage event_ = events[_eventId];
        require(event_.startTime > 0, "Event does not exist");
        require(block.timestamp < event_.startTime, "Event has already started");
        
        uint256 nftId = event_.registeredParticipants[msg.sender];
        require(nftId != 0, "Not registered");

        event_.registeredParticipants[msg.sender] = 0;
        event_.usedNftIds[nftId] = false;
        emit ParticipantDeregistered(_eventId, msg.sender, nftId);
    }

    function isRegistered(uint256 _eventId, address _participant) external view returns (bool) {
        return events[_eventId].registeredParticipants[_participant] != 0;
    }

    function getRegisteredNftId(uint256 _eventId, address _participant) external view returns (uint256) {
        return events[_eventId].registeredParticipants[_participant];
    }

    function getEventDetails(uint256 _eventId) external view returns (
        string memory name,
        uint256 startTime,
        uint256 endTime,
        address nftAddress,
        address owner
    ) {
        Event storage event_ = events[_eventId];
        require(event_.startTime > 0, "Event does not exist");
        return (event_.name, event_.startTime, event_.endTime, event_.nftAddress, event_.owner);
    }
}
