// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarInsurance {

    struct User {
        address userAddress;
        uint256 ncd;  // No Claim Discount in percentage
        uint256 premiumPaid;
        bool registered;
        uint256 lastPaymentYear; // Track last payment year for NCD adjustment
        bool hasClaimed;  // Track whether the user has made a claim this year
    }
    
    struct Policy {
        uint256 premiumAmount;
        uint256 baseNCD;  // Base NCD allowed for this policy
        uint256 carAgeFactor;  // Factor for calculating premium based on car age
        uint256 carBrandFactor;  // Factor for car brand
        uint256 claimResetNCD;  // NCD value if claim is made
        bool active;
    }

    address public insuranceCompany;
    uint256 public totalPremiumPool;
    uint256 public claimPool;
    uint256 public reinsurancePool;
    uint256 public companyProfitPool;
    
    mapping(address => User) public users;
    mapping(uint256 => Policy) public policies; // Mapping from policy ID to Policy
    uint256 public policyCount;

    // Modifiers
    modifier onlyInsuranceCompany() {
        require(msg.sender == insuranceCompany, "Only the insurance company can execute this function.");
        _;
    }

    // Constructor
    constructor() {
        insuranceCompany = msg.sender;
        policyCount = 0;
    }

    // User registers with a policy and NCD
    function registerUser(uint256 _policyId, uint256 _ncd) public payable {
        require(!users[msg.sender].registered, "User is already registered.");
        Policy memory selectedPolicy = policies[_policyId];
        require(selectedPolicy.active, "Policy is not active.");
        require(msg.value == selectedPolicy.premiumAmount, "Incorrect premium amount.");
        
        // Calculate premium based on NCD, car factors, and other variables
        uint256 premiumAmount = calculatePremium(_policyId, _ncd);
        require(msg.value >= premiumAmount, "Premium payment is too low based on NCD and policy.");

        // Register user and set the year they paid the premium
        users[msg.sender] = User(msg.sender, _ncd, msg.value, true, block.timestamp, false);
        
        // Allocate premium funds to respective pools
        allocatePremiumFunds(msg.value);
    }

    // Allocate the premium to different pools
    function allocatePremiumFunds(uint256 _premiumAmount) internal {
        // Company profits (25%)
        uint256 companyShare = (_premiumAmount * 25) / 100;
        companyProfitPool += companyShare;
        
        // Reinsurance or investment (10%)
        uint256 reinsuranceShare = (_premiumAmount * 10) / 100;
        reinsurancePool += reinsuranceShare;
        
        // Claim pool (65%)
        uint256 claimShare = (_premiumAmount * 65) / 100;
        claimPool += claimShare;
        
        totalPremiumPool += _premiumAmount;
    }

    // User can submit a claim, verified manually by the company
    function submitClaim(uint256 _claimAmount) public {
        require(users[msg.sender].registered, "User is not registered.");
        require(_claimAmount <= claimPool, "Insufficient funds in the claim pool.");
        
        // Update NCD based on claim (reset to predefined value)
        resetNCD(msg.sender);
        
        // Mark user as having claimed this year
        users[msg.sender].hasClaimed = true;

        // Submit claim for manual review by insurance company
        claimPool -= _claimAmount;
        payable(msg.sender).transfer(_claimAmount);
    }

    // Insurance company can withdraw profits (up to 25% of the pool)
    function withdrawCompanyProfits() public onlyInsuranceCompany {
        uint256 withdrawAmount = companyProfitPool;
        companyProfitPool = 0;
        payable(insuranceCompany).transfer(withdrawAmount);
    }

    // Add new policy (only by the insurance company)
    function addPolicy(
        uint256 _premiumAmount,
        uint256 _baseNCD,
        uint256 _carAgeFactor,
        uint256 _carBrandFactor,
        uint256 _claimResetNCD
    ) public onlyInsuranceCompany {
        policies[policyCount] = Policy(
            _premiumAmount, 
            _baseNCD, 
            _carAgeFactor, 
            _carBrandFactor, 
            _claimResetNCD, 
            true
        );
        policyCount++;
    }
    
    // Insurance company invests reinsurance pool
    function investReinsuranceFunds(uint256 _amount, address _investmentAddress) public onlyInsuranceCompany {
        require(_amount <= reinsurancePool, "Insufficient reinsurance pool funds.");
        reinsurancePool -= _amount;
        payable(_investmentAddress).transfer(_amount);
    }

    // NCD Management and Yearly Update
    function updateNCD() public {
        require(users[msg.sender].registered, "User is not registered.");
        User storage user = users[msg.sender];

        // Ensure user hasn't missed a payment year
        uint256 currentYear = block.timestamp;
        if (currentYear - user.lastPaymentYear >= 365 * 24 * 60 * 60 && !user.hasClaimed) {
            // Increase NCD if no claims were made and premium is paid on time
            user.ncd += 5;  // Increase NCD by 5% for each year without a claim
            user.lastPaymentYear = currentYear;
        } else if (currentYear - user.lastPaymentYear >= 365 * 24 * 60 * 60 && user.hasClaimed) {
            resetNCD(msg.sender);
        }

        // Reset claim status for the next year
        user.hasClaimed = false;
    }

    // Reset the user's NCD after a claim
    function resetNCD(address _userAddress) internal {
        users[_userAddress].ncd = policies[0].claimResetNCD;  // Reset NCD based on the policy
    }

    // Calculate premium based on policy and NCD
    function calculatePremium(uint256 _policyId, uint256 _ncd) public view returns (uint256) {
        Policy memory policy = policies[_policyId];

        // Adjust premium based on NCD
        uint256 discountedPremium = policy.premiumAmount * (100 - _ncd) / 100;
        
        // Further adjust premium based on car factors (age, brand, etc.)
        uint256 adjustedPremium = discountedPremium * policy.carAgeFactor / 100;
        adjustedPremium = adjustedPremium * policy.carBrandFactor / 100;

        return adjustedPremium;
    }

    // Fallback function to receive ether
    receive() external payable {}
}
