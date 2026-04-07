// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IncidentRegistry
 * @dev Stores tamper-proof incident and evidence hashes on blockchain
 * @notice For SHEILD Women Safety App
 * @notice Deployed on Polygon Amoy Testnet (FREE)
 *
 * As described in the SHEILD research paper:
 * - Stores SHA-256 incident hash
 * - Stores IPFS CID for off-chain evidence
 * - Records owner address and timestamp
 * - Provides verification for police/courts
 * - Access control for evidence viewing
 */
contract IncidentRegistry {

    struct Evidence {
        bytes32 evidenceHash;    // SHA-256 hash of the original file
        string  ipfsCid;         // IPFS Content Identifier for encrypted file
        address owner;           // Wallet address that submitted the evidence
        uint256 timestamp;       // Block timestamp when recorded
        bool    exists;          // Whether this record exists
    }

    // incident hash => whether it's been recorded
    mapping(bytes32 => bool) public incidentHashes;

    // evidence ID (counter) => Evidence struct
    mapping(uint256 => Evidence) public evidenceRecords;

    // evidence hash => evidence ID (for lookup by hash)
    mapping(bytes32 => uint256) public evidenceIdByHash;

    // owner => list of their evidence IDs
    mapping(address => uint256[]) private _ownerEvidenceIds;

    // evidence ID => address => whether they have access
    mapping(uint256 => mapping(address => bool)) private _accessControl;

    uint256 public totalIncidents;
    uint256 public totalEvidence;

    event IncidentRecorded(
        bytes32 indexed incidentHash,
        address indexed userAddress,
        uint256 timestamp,
        uint256 blockNumber
    );

    event EvidenceRegistered(
        uint256 indexed evidenceId,
        bytes32 indexed evidenceHash,
        string  ipfsCid,
        address indexed owner,
        uint256 timestamp
    );

    event AccessGranted(
        uint256 indexed evidenceId,
        address indexed grantedTo,
        address indexed grantedBy
    );

    // ===================== INCIDENT FUNCTIONS =====================

    /**
     * @dev Store an incident hash on the blockchain
     * @param _incidentHash SHA-256 hash of the incident data
     */
    function recordIncident(bytes32 _incidentHash) public returns (bool) {
        require(!incidentHashes[_incidentHash], "Hash already exists");

        incidentHashes[_incidentHash] = true;
        totalIncidents++;

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
     */
    function verifyIncident(bytes32 _incidentHash) public view returns (bool) {
        return incidentHashes[_incidentHash];
    }

    // ===================== EVIDENCE FUNCTIONS =====================

    /**
     * @dev Register evidence with hash and IPFS CID.
     *      Called after encrypting file, uploading to IPFS,
     *      and computing SHA-256 of original plaintext.
     * @param _evidenceHash SHA-256 hash of the ORIGINAL (unencrypted) file
     * @param _ipfsCid      IPFS Content Identifier of the ENCRYPTED file
     * @return evidenceId   The unique ID assigned to this evidence
     */
    function registerEvidence(
        bytes32 _evidenceHash,
        string calldata _ipfsCid
    ) public returns (uint256) {
        require(_evidenceHash != bytes32(0), "Empty hash");
        require(bytes(_ipfsCid).length > 0, "Empty CID");
        require(evidenceIdByHash[_evidenceHash] == 0, "Evidence already registered");

        totalEvidence++;
        uint256 evidenceId = totalEvidence;

        evidenceRecords[evidenceId] = Evidence({
            evidenceHash: _evidenceHash,
            ipfsCid: _ipfsCid,
            owner: msg.sender,
            timestamp: block.timestamp,
            exists: true
        });

        evidenceIdByHash[_evidenceHash] = evidenceId;
        _ownerEvidenceIds[msg.sender].push(evidenceId);

        // Owner always has access
        _accessControl[evidenceId][msg.sender] = true;

        emit EvidenceRegistered(
            evidenceId,
            _evidenceHash,
            _ipfsCid,
            msg.sender,
            block.timestamp
        );

        return evidenceId;
    }

    /**
     * @dev Verify evidence integrity: check hash exists and return metadata
     */
    function verifyEvidence(bytes32 _evidenceHash) public view returns (
        bool exists,
        uint256 evidenceId,
        string memory ipfsCid,
        address owner,
        uint256 timestamp
    ) {
        uint256 id = evidenceIdByHash[_evidenceHash];
        if (id == 0 || !evidenceRecords[id].exists) {
            return (false, 0, "", address(0), 0);
        }
        Evidence storage e = evidenceRecords[id];
        return (true, id, e.ipfsCid, e.owner, e.timestamp);
    }

    /**
     * @dev Grant access to evidence for a specific address (e.g. police)
     */
    function grantAccess(uint256 _evidenceId, address _to) public {
        require(evidenceRecords[_evidenceId].exists, "Evidence not found");
        require(evidenceRecords[_evidenceId].owner == msg.sender, "Not owner");

        _accessControl[_evidenceId][_to] = true;

        emit AccessGranted(_evidenceId, _to, msg.sender);
    }

    /**
     * @dev Check if an address has access to evidence
     */
    function hasAccess(uint256 _evidenceId, address _addr) public view returns (bool) {
        return _accessControl[_evidenceId][_addr];
    }

    /**
     * @dev Get all evidence IDs owned by the caller
     */
    function getMyEvidenceIds() public view returns (uint256[] memory) {
        return _ownerEvidenceIds[msg.sender];
    }

    /**
     * @dev Get total number of incidents recorded
     */
    function getTotalIncidents() public view returns (uint256) {
        return totalIncidents;
    }
}

