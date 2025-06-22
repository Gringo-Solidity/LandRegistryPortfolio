// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LandRegistry {
    struct Plot {
        uint id;
        bytes32 coordinates;
        address owner;
    }

    address public owner;
    uint public plotCount;
    uint public registrationFee = 0.01 ether;

    mapping(uint => Plot) public plots;
    mapping(bytes32 => bool) private registeredCoordinates;
    mapping(address => uint[]) private ownerPlots;

    event PlotRegistered(uint indexed id, bytes32 coordinates, address indexed owner);
    event OwnershipTransferred(uint indexed plotId, address indexed previousOwner, address indexed newOwner);
    event RegistrationFeeChanged(uint newFee);
    event OwnershipRenounced(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerPlot(bytes32 _coordinates) public payable {
        require(msg.value == registrationFee, "Incorrect registration fee");
        require(!registeredCoordinates[_coordinates], "Coordinates already registered");

        plotCount++;
        plots[plotCount] = Plot(plotCount, _coordinates, msg.sender);
        registeredCoordinates[_coordinates] = true;
        ownerPlots[msg.sender].push(plotCount);

        emit PlotRegistered(plotCount, _coordinates, msg.sender);
    }

    function transferOwnership(uint _plotId, address _newOwner) public {
        require(msg.sender == plots[_plotId].owner, "Only owner can transfer");
        require(_newOwner != address(0), "Cannot transfer to zero address");

        address previousOwner = plots[_plotId].owner;
        plots[_plotId].owner = _newOwner;

        _removePlotFromOwner(previousOwner, _plotId);
        ownerPlots[_newOwner].push(_plotId);

        emit OwnershipTransferred(_plotId, previousOwner, _newOwner);
    }

    function _removePlotFromOwner(address _owner, uint _plotId) private {
        uint[] storage plotsList = ownerPlots[_owner];
        for (uint i = 0; i < plotsList.length; i++) {
            if (plotsList[i] == _plotId) {
                plotsList[i] = plotsList[plotsList.length - 1];
                plotsList.pop();
                break;
            }
        }
    }

    function setRegistrationFee(uint _newFee) external onlyOwner {
        registrationFee = _newFee;
        emit RegistrationFeeChanged(_newFee);
    }

    function transferContractOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Cannot transfer to zero address");
        emit OwnershipRenounced(owner, _newOwner);
        owner = _newOwner;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getPlot(uint _plotId) public view returns (Plot memory) {
        return plots[_plotId];
    }

    function getPlotsByOwner(address _owner) public view returns (uint[] memory) {
        return ownerPlots[_owner];
    }

    function isRegistered(bytes32 _coordinates) public view returns (bool) {
        return registeredCoordinates[_coordinates];
    }
}
