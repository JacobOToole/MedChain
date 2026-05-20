// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AuditLog.sol";
import "./PatientRegistry.sol";
import "./ProviderRegistry.sol";
import "./AccessControl.sol";
import "./RecordManager.sol";

contract Deployer {
    AuditLog         public auditLog;
    PatientRegistry  public patientRegistry;
    ProviderRegistry public providerRegistry;
    AccessControl    public accessControl;
    RecordManager    public recordManager;

    address public hospitalAdmin;

    constructor(address _hospitalAdmin) {
        require(_hospitalAdmin != address(0), "Deployer: zero hospitalAdmin");
        hospitalAdmin = _hospitalAdmin;

        // AuditLog has no dependencies, registries are
        // independent, AccessControl depends on the two registries + audit
        // log, RecordManager depends on AccessControl + audit log.
        auditLog         = new AuditLog();
        patientRegistry  = new PatientRegistry();
        providerRegistry = new ProviderRegistry(_hospitalAdmin);
        accessControl    = new AccessControl(
            address(patientRegistry),
            address(providerRegistry),
            address(auditLog)
        );
        recordManager    = new RecordManager(
            address(accessControl),
            address(auditLog)
        );

        // Austhorise other contracts that need to write to it.
        auditLog.authorise(address(accessControl));
        auditLog.authorise(address(recordManager));

        // Hand AuditLog ownership over to the hospital admin so they can
        // add/remove future writers without involving the deployer EOA.
        auditLog.transferOwnership(_hospitalAdmin);
    }

    function systemStatus() external view returns (
            address _hospitalAdmin,
            address _auditLogOwner,
            uint256 _patientCount,
            uint256 _providerCount,
            uint256 _recordCount,
            uint256 _auditLogCount
        )
    {
        _hospitalAdmin = hospitalAdmin;
        _auditLogOwner = auditLog.owner();
        _patientCount  = patientRegistry.patientCount();
        _providerCount = providerRegistry.providerCount();
        _recordCount   = recordManager.recordCount();
        _auditLogCount = auditLog.getLogCount();
    }
}