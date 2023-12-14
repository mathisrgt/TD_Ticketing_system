// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract TicketingSystem {
    // VARIABLES AND STRUCTS

    struct artist {
        bytes32 name;
        uint256 artistCategory;
        address owner;
        uint256 totalTicketSold;
    }

    struct venue {
        bytes32 name;
        uint256 capacity;
        uint256 standardComission;
        address payable owner;
    }

    struct concert {
        uint256 artistId;
        uint256 venueId;
        uint256 concertDate;
        uint256 ticketPrice;
        bool validatedByArtist;
        bool validatedByVenue;
        uint256 totalSoldTicket;
        uint256 totalMoneyCollected;
    }

    struct ticket {
        uint256 concertId;
        address payable owner;
        bool isAvailable;
        bool isAvailableForSale;
        uint256 amountPaid;
    }

    uint256 public artistCount = 0;
    uint256 public venueCount = 0;
    uint256 public concertCount = 0;
    uint256 public ticketCount = 0;

    mapping(uint256 => artist) public artistsRegister;
    mapping(bytes32 => uint256) private artistsID;

    mapping(uint256 => venue) public venuesRegister;
    mapping(bytes32 => uint256) private venuesID;

    mapping(uint256 => concert) public concertsRegister;
    mapping(uint256 => ticket) public ticketsRegister;

    event CreatedArtist(bytes32 name, uint256 id);
    event ModifiedArtist(bytes32 name, uint256 id, address sender);
    event CreatedVenue(bytes32 name, uint256 id);
    event ModifiedVenue(bytes32 name, uint256 id);
    event CreatedConcert(uint256 concertDate, bytes32 name, uint256 id);

    constructor() {}

    // ARTISTS FUNCTIONS

    function createArtist(bytes32 _name, uint256 _artistCategory) public {
        artistCount++;
        artistsRegister[artistCount] = artist(
            _name,
            _artistCategory,
            msg.sender,
            0
        );
        artistsID[_name] = artistCount;
        emit CreatedArtist(_name, artistCount);
    }

    function getArtistId(bytes32 _name) public view returns (uint256 ID) {
        return artistsID[_name];
    }

    function modifyArtist(
        uint256 _artistId,
        bytes32 _name,
        uint256 _artistCategory,
        address payable _newOwner
    ) public {
        artist storage currentArtist = artistsRegister[_artistId];
        require(msg.sender == currentArtist.owner, "not the owner");

        currentArtist.name = _name;
        currentArtist.artistCategory = _artistCategory;

        // Check if owner has changed and update the new owner
        if (currentArtist.owner != _newOwner) {
            currentArtist.owner = _newOwner;
        }

        emit ModifiedArtist(_name, _artistId, msg.sender);
    }

    // VENUES FUNCTIONS

    function createVenue(
        bytes32 _name,
        uint256 _capacity,
        uint256 _standardComission
    ) public {
        venueCount++;
        address payable ownerAddress = payable(msg.sender);
        venuesRegister[venueCount] = venue(
            _name,
            _capacity,
            _standardComission,
            ownerAddress
        );
        venuesID[_name] = venueCount;
        emit CreatedVenue(_name, venueCount);
    }

    function getVenueId(bytes32 _name) public view returns (uint256 ID) {
        return venuesID[_name];
    }

    function modifyVenue(
        uint256 _venueId,
        bytes32 _name,
        uint256 _capacity,
        uint256 _standardComission,
        address payable _newOwner
    ) public {
        require(
            msg.sender == venuesRegister[_venueId].owner,
            "not the venue owner"
        );
        venuesRegister[_venueId].name = _name;
        venuesRegister[_venueId].capacity = _capacity;
        venuesRegister[_venueId].standardComission = _standardComission;
        venuesRegister[_venueId].owner = _newOwner;
        emit ModifiedVenue(_name, _venueId);
    }

    // CONCERTS FUNCTIONS

    function createConcert(
        uint256 _artistId,
        uint256 _venueId,
        uint256 _concertDate,
        uint256 _ticketPrice
    ) public {
        concertCount++;

        bool validatedByArtistTmp = false;
        bool validatedByVenueTmp = false;

        if (payable(msg.sender) == artistsRegister[_artistId].owner) {
            validatedByArtistTmp = true;
        }
        if (payable(msg.sender) == venuesRegister[_venueId].owner) {
            validatedByVenueTmp = true;
        }

        concertsRegister[concertCount] = concert(
            _artistId,
            _venueId,
            _concertDate,
            _ticketPrice,
            validatedByArtistTmp,
            validatedByVenueTmp,
            0,
            0
        );

        emit CreatedConcert(
            _concertDate,
            venuesRegister[_venueId].name,
            concertCount
        );
    }

    function validateConcert(uint256 _concertId) public {
        concert storage concertTemp = concertsRegister[_concertId];

        if (
            artistsRegister[concertTemp.artistId].owner == payable(msg.sender)
        ) {
            concertTemp.validatedByArtist = true;
        }
        if (venuesRegister[concertTemp.venueId].owner == payable(msg.sender)) {
            concertTemp.validatedByVenue = true;
        }
    }

    function emitTicket(
        uint256 _concertId,
        address payable _ticketOwner
    ) public {
        require(
            msg.sender ==
                artistsRegister[concertsRegister[_concertId].artistId].owner,
            "not the owner"
        );
        ticketCount++;
        concertsRegister[_concertId].totalSoldTicket++;
        ticketsRegister[ticketCount] = ticket(
            _concertId,
            _ticketOwner,
            true,
            false,
            0
        );
    }

    // BUY/TRANSFER FUNCTIONS

    function buyTicket(uint256 _concertId) public payable {
        concert storage currentConcert = concertsRegister[_concertId];
        require(
            currentConcert.validatedByArtist && currentConcert.validatedByVenue,
            "concert not validated"
        );
        require(
            msg.value >= currentConcert.ticketPrice,
            "not enough funds"
        );

        ticketCount++;
        ticketsRegister[ticketCount] = ticket(
            _concertId,
            payable(msg.sender),
            true,
            false,
            msg.value
        );
        currentConcert.totalSoldTicket++;
        currentConcert.totalMoneyCollected += msg.value;
    }

    function transferTicket(
        uint256 _ticketId,
        address payable _newOwner
    ) public {
        require(_ticketId > 0 && _ticketId <= ticketCount, "invalid ticket ID");
        ticket storage currentTicket = ticketsRegister[_ticketId];
        require(currentTicket.owner == msg.sender, "not the ticket owner");
        currentTicket.owner = _newOwner;
    }

    function useTicket(uint256 _ticketId) public {
        require(_ticketId > 0 && _ticketId <= ticketCount, "invalid ticket ID");
        ticket storage currentTicket = ticketsRegister[_ticketId];
        require(
            currentTicket.owner == msg.sender,
            "sender should be the owner"
        );
        require(currentTicket.isAvailable == true, "ticket is not available");
        require(
            block.timestamp + 60 * 60 * 24 >=
                concertsRegister[currentTicket.concertId].concertDate,
            "should be used the d-day"
        );
        require(
            concertsRegister[currentTicket.concertId].validatedByVenue,
            "should be validated by the venue"
        );

        currentTicket.isAvailable = false;
        currentTicket.isAvailableForSale = false;
        currentTicket.owner = payable(address(0));
        currentTicket.amountPaid = 0;
    }

    // CONCERT CASHOUT FUNCTION

    function cashOutConcert(
        uint256 _concertId,
        address payable _cashOutAddress
    ) public {
        require(
            block.timestamp >= concertsRegister[_concertId].concertDate,
            "should be after the concert"
        );
        require(
            artistsRegister[concertsRegister[_concertId].artistId].owner ==
                msg.sender,
            "should be the artist"
        );

        uint256 totalTicketSales = concertsRegister[_concertId].ticketPrice *
            concertsRegister[_concertId].totalSoldTicket;
        uint256 venueShare = (totalTicketSales *
            venuesRegister[concertsRegister[_concertId].venueId]
                .standardComission) / 10000;
        uint256 artistShare = totalTicketSales - venueShare;

        _cashOutAddress.call{value: artistShare}("");
        venuesRegister[concertsRegister[_concertId].venueId].owner.call{value: venueShare}("");

        artistsRegister[concertsRegister[_concertId].artistId]
            .totalTicketSold += concertsRegister[_concertId].totalSoldTicket;
    }

    // TICKET SELLING FUNCTIONS

    function offerTicketForSale(uint256 _ticketId, uint256 _salePrice) public {
        ticket storage currentTicket = ticketsRegister[_ticketId];
        require(
            currentTicket.owner == msg.sender,
            "should be the owner"
        );
        require(
            _salePrice < currentTicket.amountPaid,
            "should be less than the amount paid"
        );
        currentTicket.isAvailableForSale = true;
        currentTicket.amountPaid = _salePrice;
    }

    function buySecondHandTicket(uint256 _ticketId) public payable {
        ticket storage currentTicket = ticketsRegister[_ticketId];
        require(
            currentTicket.isAvailableForSale == true,
            "should be available"
        );
        require(msg.value >= currentTicket.amountPaid, "not enough funds");

        currentTicket.owner.transfer(msg.value);
        currentTicket.owner = payable(msg.sender);
        currentTicket.isAvailableForSale = false;
        currentTicket.amountPaid = 0;
    }
}
