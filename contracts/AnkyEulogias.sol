// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyEulogias is ERC1155, Ownable, ERC1155Supply {
    using Counters for Counters.Counter;
    Counters.Counter private _eulogiaIds;


    struct Eulogia {
        uint256 eulogiaId;
        string metadataCID;
        uint256 maxMessages;
    }

    mapping(uint256 => Eulogia) public eulogias;

    mapping(uint256 => address[]) public eulogiaOwners;
    mapping(address => uint256[]) public userCreatedEulogias;
    mapping(address => uint256[]) public eulogiasWhereUserWrote;
    mapping(address => uint256[]) public userOwnedEulogias;

    IAnkyAirdrop public ankyAirdrop;

    event EulogiaCreated(uint256 indexed eulogiaId, address indexed eulogiaCreator, string metadataCID);
    event EulogiaMinted(uint256 indexed eulogiaId, address indexed newOwner);

    modifier onlyAnkyOwner() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Must own an Anky");
        _;
    }

    constructor(address _ankyAirdrop) ERC1155("") Ownable() {
                ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    function createEulogia(string memory metadataCID, uint256 maxMsgs ) external onlyAnkyOwner {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        require(maxMsgs <= 500, "Max messages for a Eulogia is 500");

        _eulogiaIds.increment();
        uint256 newEulogiaId = _eulogiaIds.current();

        eulogias[newEulogiaId] = Eulogia({
            eulogiaId: newEulogiaId,
            metadataCID: metadataCID,
            maxMessages: maxMsgs
        });

        emit EulogiaCreated(newEulogiaId, usersAnkyAddress, metadataCID);
    }

    function mintEulogia(uint256 eulogiaId) external onlyAnkyOwner {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(balanceOf(usersAnkyAddress, eulogiaId) == 0, "You already own a copy of this eulogia");

        _mint(usersAnkyAddress, eulogiaId, 1, "");
        eulogiaOwners[eulogiaId].push(usersAnkyAddress);
        userOwnedEulogias[usersAnkyAddress].push(eulogiaId);
        emit EulogiaMinted(eulogiaId, usersAnkyAddress);
    }

    function getEulogia(uint256 eulogiaId) external view returns(Eulogia memory) {
        return eulogias[eulogiaId];
    }

    function getUserCreatedEulogias() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userCreatedEulogias[usersAnkyAddress];
    }

    function getUserWrittenEulogias() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return eulogiasWhereUserWrote[usersAnkyAddress];
    }

    function getUserOwnedEulogias() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userOwnedEulogias[usersAnkyAddress];
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
