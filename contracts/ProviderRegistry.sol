// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProviderRegistry {
    address public hospitalAdmin;

    struct Provider {
        address wallet;
        string  name;
        bool    active;
    }

    mapping(address => Provider) private providers;
    address[] private providerList;

    event ProviderRegistered(address indexed provider, string name, uint256 timestamp);
        event ProviderRevoked(address indexed provider, uint256 timestamp);

    modifier onlyAdmin() {
        require(msg.sender == hospitalAdmin, "ProviderRegistry: not hospital admin");
        _;
    }

    constructor(address _hospitalAdmin) {
        require(_hospitalAdmin != address(0), "ProviderRegistry: zero admin");
        hospitalAdmin = _hospitalAdmin;
    }

    function registerProvider(address providerAdd, string calldata name) external onlyAdmin {
        require(providerAdd != address(0), "ProviderRegistry: zero address");
        bool isNew = providers[providerAdd].wallet == address(0);

        providers[providerAdd] = Provider({
            wallet: providerAdd,
            name: name,
            active: true
        });

        if (isNew) providerList.push(providerAdd);
        emit ProviderRegistered(providerAdd, name, block.timestamp);
    }

    function revokeProvider(address providerAdd) external onlyAdmin {
        require(isActiveProvider(providerAdd), "Provider Registry: provider not active");
        providers[providerAdd].active = false;
        emit ProviderRevoked(providerAdd, block.timestamp);
    }

    function isActiveProvider(address addr) public view returns (bool) {
        return providers[addr].active;
    }

    function getProvider(address addr) external view returns (Provider memory) {
        return providers[addr];
    }

    function providerCount() external view returns (uint256) {
        return providerList.length;
    }
}