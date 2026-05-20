// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAccessControl {
    function checkAccess(address patient, address provider) external view returns (bool);
}

interface IAuditLog {
    function logEvent(address actor, address subject, address counterparty, string calldata action) external;
}

contract RecordManager {
    IAccessControl public accessControl;
    IAuditLog    public auditLog;

    // Comments suggest potential fields... look into these if enough time
    struct Record {
        address provider;
        address patient;
        string  cid;             // CID of encrypted file on IPFS
        uint256 timestamp; 
        uint256 previousVersion; // 0 if original
        bool    superseded;      // true if not newest version
    }

    Record[] private records;
    mapping(address => uint256[]) private patientRecords; // patient => record ids

    event RecordUploaded(
        address indexed patient,
        address indexed provider,
        string cid,
        uint256 timestamp
    );
    event RecordUpdated(
        uint256 indexed newId,
        uint256 indexed previousId,
        address indexed patient,
        string cid,
        uint256 timestamp
    );

    constructor(address _accessControl, address _auditLog) {
        require(_accessControl != address(0), "RecordManager: zero accessControl");
        require(_auditLog != address(0), "RecordManager: zero auditLog");
        accessControl = IAccessControl(_accessControl);
        auditLog      = IAuditLog(_auditLog);
    }

    // TODO: functions

    function uploadRecord(address patient, string calldata cid) external returns (uint256) {
        // Check access permissions
        require(accessControl.checkAccess(patient, msg.sender), "RecordManager: not authorized");
        
        records.push(Record({
            provider: msg.sender,
            patient: patient,
            cid: cid,
            timestamp: block.timestamp,
            previousVersion: 0,
            superseded: false
        }));

        uint256 id = records.length - 1;
        patientRecords[patient].push(id);
        emit RecordUploaded(patient, msg.sender, cid, block.timestamp);
        // actor = provider, subject = patient. No counterparty: address == 0
        auditLog.logEvent(msg.sender, patient, address(0), "UPLOAD_RECORD");
        return id;
    }

    function updateRecord(uint256 previousId, string calldata cid) external returns (uint256) {
        // Check valid id, isn't already superseded, access permission
        require(previousId < records.length, "RecordManager: invalid record id");
        Record storage prev = records[previousId];
        require(!prev.superseded, "RecordManager: previous already superseded");
        require(
            accessControl.checkAccess(prev.patient, msg.sender),
            "RecordManager: not authorized"
        );

        address patient = prev.patient;
        // mark previous as superseded
        prev.superseded = true;

        records.push(Record({
            provider: msg.sender,
            patient: patient,
            cid: cid,
            timestamp: block.timestamp,
            previousVersion: previousId,
            superseded: false
        }));

        uint256 newId = records.length - 1;
        patientRecords[patient].push(newId);
        emit RecordUpdated(newId, previousId, patient, cid, block.timestamp);
        auditLog.logEvent(msg.sender, patient, address(0), "UPDATE_RECORD");
        return newId;
    }

    function getRecord(uint256 id) external view returns (Record memory) {
        require(id < records.length, "RecordManager: invalid id");
        Record memory r = records[id];
        require(
            msg.sender == r.patient ||
            accessControl.checkAccess(r.patient, msg.sender),
            "RecordManager: not authorized to view"
        );
        return r;
    }

    function recordCount() external view returns (uint256) {
        return records.length;
    }
} 
