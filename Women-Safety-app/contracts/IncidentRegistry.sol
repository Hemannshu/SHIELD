// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IncidentRegistry
 * @dev Simple contract to store tamper-proof incident hashes on blockchain
 * @notice For Shield Women Safety App - College Project
 * @notice Uses Polygon Mumbai Testnet (FREE)
 */
contract IncidentRegistry {
    // Event emitted when an incident hash is stored
    event IncidentRecorded(
        bytes32 indexed incidentHash,
        address indexed userAddress,
        uint256 timestamp,
        uint256 blockNumber
    );

    // Mapping to check if a hash has been recorded
    mapping(bytes32 => bool) public incidentHashes;

    // Total incidents recorded
    uint256 public totalIncidents;

    /**
     * @dev Store an incident hash on the blockchain
     * @param _incidentHash SHA-256 hash of the incident data
     * @return success True if hash was successfully stored
     */
    function recordIncident(bytes32 _incidentHash) public returns (bool) {
        // Prevent duplicate hashes
        require(!incidentHashes[_incidentHash], "Hash already exists");

        // Mark hash as recorded
        incidentHashes[_incidentHash] = true;
        totalIncidents++;

        // Emit event for easy querying
        emit IncidentRecorded(
            _incidentHash,
            msg.sender,
            block.timestamp,
            block.number
        );

        return true;
    }

    /**
     * @dev Verify if an incident hash exists on blockchain
     * @param _incidentHash Hash to verify
     * @return exists True if hash exists, false otherwise
     */
    function verifyIncident(bytes32 _incidentHash) public view returns (bool) {
        return incidentHashes[_incidentHash];
    }

    /**
     * @dev Get total number of incidents recorded
     * @return count Total incidents
     */
    function getTotalIncidents() public view returns (uint256) {
        return totalIncidents;
    }
}

