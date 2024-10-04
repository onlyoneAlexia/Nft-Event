// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract EventRegistration {
    // Defined a struct to store event details
    struct Event {
        string name;
        uint256 startTime;
        uint256 endTime;
        address nftAddress;
        address owner;
        mapping(address => uint256) registeredParticipants; // Maps participant address to NFT ID
        mapping(uint256 => bool) usedNftIds; // Tracks used NFT IDs
    }

    // Store all events, indexed by event ID
    mapping(uint256 => Event) public events;
    // Keep track of the total number of events
    uint256 public eventCount;

    // Events for logging important actions
    event EventCreated(uint256 indexed eventId, string name, address owner);
    event ParticipantRegistered(uint256 indexed eventId, address participant, uint256 nftId);
    event ParticipantDeregistered(uint256 indexed eventId, address participant, uint256 nftId);

    
    function createEvent(string memory _name, uint256 _startTime, uint256 _endTime, address _nftAddress) external {
        // Validate input parameters
        require(_startTime < _endTime, "Invalid time range");
        require(_nftAddress != address(0), "Invalid NFT address");

        // Create and store the new event
        eventCount++;
        Event storage newEvent = events[eventCount];
        newEvent.name = _name;
        newEvent.startTime = _startTime;
        newEvent.endTime = _endTime;
        newEvent.nftAddress = _nftAddress;
        newEvent.owner = msg.sender;

        // tell us an event was created
        emit EventCreated(eventCount, _name, msg.sender);
    }

    // Function to register for an event using an NFT
    function registerForEvent(uint256 _eventId, uint256 _nftId) external {
        Event storage event_ = events[_eventId];
        require(event_.startTime > 0, "Event does not exist");
        require(event_.registeredParticipants[msg.sender] == 0, "Already registered");
        require(!event_.usedNftIds[_nftId], "NFT ID already used");

        // Verify NFT ownership
        IERC721 nft = IERC721(event_.nftAddress);
        require(nft.ownerOf(_nftId) == msg.sender, "Must own the specified NFT");

        emit ParticipantRegistered(_eventId, msg.sender, _nftId);
    }

      
    // Function to get event details
    function getEventDetails(uint256 _eventId) external view returns (
        string memory name,
        uint256 startTime,
        uint256 endTime,
        address nftAddress,
        address owner
    ) {
        Event storage event_ = events[_eventId];
        // Check if the event exists
        require(event_.startTime > 0, "Event does not exist");
        return (event_.name, event_.startTime, event_.endTime, event_.nftAddress, event_.owner);
    }
}