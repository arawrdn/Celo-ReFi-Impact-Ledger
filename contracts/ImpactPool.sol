// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ImpactPool
 * @dev Manages project listings and accepts cUSD/cEUR donations.
 */
contract ImpactPool is Ownable {
    // === STATE VARIABLES ===
    
    // cUSD token address on Celo (e.g., Alfajores/Mainnet address)
    IERC20 public cUSDToken; 

    // Struct to hold project information
    struct Project {
        string name;
        address beneficiary;
        uint256 fundingTarget;
        uint256 currentBalance;
        bool isActive;
    }

    // Mapping: Project ID => Project Details
    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId = 1;

    // === EVENTS ===

    event ProjectAdded(uint256 id, string name, address beneficiary, uint256 target);
    event DepositMade(uint256 projectId, address indexed donor, uint256 amount);
    event FundsWithdrawn(uint256 projectId, address indexed beneficiary, uint256 amount);

    // === CONSTRUCTOR ===

    constructor(address _cUSDAddress) {
        cUSDToken = IERC20(_cUSDAddress);
    }

    // === ADMIN FUNCTIONS ===

    /**
     * @dev Allows the owner to add a new environmental project.
     * @param _name Name of the project.
     * @param _beneficiary Wallet address that receives the funds.
     * @param _target The funding goal in cUSD (wei).
     */
    function addProject(
        string memory _name,
        address _beneficiary,
        uint256 _target
    ) public onlyOwner {
        require(_target > 0, "Target must be greater than zero");
        projects[nextProjectId] = Project({
            name: _name,
            beneficiary: _beneficiary,
            fundingTarget: _target,
            currentBalance: 0,
            isActive: true
        });
        emit ProjectAdded(nextProjectId, _name, _beneficiary, _target);
        nextProjectId++;
    }

    // === CORE DONATION FUNCTIONALITY ===

    /**
     * @dev Allows users to donate cUSD to a specific project.
     * NOTE: Requires the donor to call 'approve' on the cUSD contract first.
     * @param _projectId ID of the project to donate to.
     * @param _amount Amount of cUSD (wei) to transfer.
     */
    function deposit(uint256 _projectId, uint256 _amount) public {
        Project storage project = projects[_projectId];
        require(project.isActive, "Project is not active");
        require(_amount > 0, "Amount must be greater than zero");

        // 1. Transfer cUSD from donor to this contract
        bool success = cUSDToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "cUSD transfer failed");

        // 2. Update project balance
        project.currentBalance += _amount;

        emit DepositMade(_projectId, msg.sender, _amount);

        // (Future step: Mint ImpactNFT here)
    }

    // === WITHDRAWAL FUNCTIONALITY ===

    /**
     * @dev Allows the project beneficiary to withdraw funds.
     * Requires current balance to be non-zero.
     */
    function withdrawFunds(uint256 _projectId) public {
        Project storage project = projects[_projectId];
        require(msg.sender == project.beneficiary, "Only beneficiary can withdraw");
        require(project.currentBalance > 0, "No funds available for withdrawal");

        uint256 amountToWithdraw = project.currentBalance;
        project.currentBalance = 0;

        // 1. Transfer cUSD from this contract to the beneficiary
        bool success = cUSDToken.transfer(project.beneficiary, amountToWithdraw);
        require(success, "cUSD transfer failed");

        emit FundsWithdrawn(_projectId, project.beneficiary, amountToWithdraw);
    }
}
