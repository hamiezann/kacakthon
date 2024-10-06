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
        uint256 policyId;  // Track the policy this user registered for
        string carType;
        uint256 carAge;
        string carBrand;
    }
    
    struct Policy {
        string name;
        uint256 premiumAmount;
        uint256 baseNCD;  // Base NCD allowed for this policy
        uint256 carAgeFactor;  // Factor for calculating premium based on car age
        uint256 carBrandFactor;  // Factor for car brand
        uint256 claimResetNCD;  // NCD value if claim is made
        bool active;
    }

    struct Transaction {
        uint256 policyId;
        uint256 ncd;
        uint256 premiumAmount;
        address user;
        uint256 timestamp;
    }

    Transaction[] public transactions;

    address public insuranceCompany;
    uint256 public totalPremiumPool;
    uint256 public claimPool;
    uint256 public reinsurancePool;
    uint256 public companyProfitPool;
    
    mapping(address => User) public users;
    mapping(uint256 => Policy) public policies; // Mapping from policy ID to Policy
    uint256 public policyCount;

    // Event to emit upon user registration
    event UserRegistered(address indexed user, uint256 policyId, uint256 premiumPaid, uint256 ncd, string carType, uint256 carAge, string carBrand);

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

    // Validate if the selected policy exists and is active
    function validatePolicy(uint256 _policyId) internal view returns (bool) {
        require(_policyId < policyCount, "Policy does not exist.");
        require(policies[_policyId].active, "Policy is not active.");
        return true;
    }

    // Validate the NCD provided by the user
    function validateNCD(uint256 _ncd, uint256 _policyId) internal view returns (bool) {
        require(_ncd <= policies[_policyId].baseNCD, "NCD exceeds the base NCD for this policy.");
        return true;
    }

    // View function to calculate the premium for the user before registration
    function calculatePremium(uint256 _policyId, uint256 _ncd, uint256 _carAge, uint256 _carBrandFactor) public view returns (uint256) {
        Policy memory policy = policies[_policyId];

        // Adjust premium based on NCD
        uint256 discountedPremium = policy.premiumAmount * (100 - _ncd) / 100;
        
        // Further adjust premium based on car factors (age, brand, etc.)
        uint256 adjustedPremium = discountedPremium * _carAge / 100;
        adjustedPremium = adjustedPremium * _carBrandFactor / 100;

        return adjustedPremium;
    }

    // Register user for a selected policy
    function registerUser(
        uint256 _policyId, 
        uint256 _ncd, 
        string memory _carType, 
        uint256 _carAge, 
        string memory _carBrand
    ) public payable {
        require(!users[msg.sender].registered || block.timestamp >= users[msg.sender].lastPaymentYear + 365 days, "User is already registered for the year.");

        // Validate policy and NCD
        validatePolicy(_policyId);
        validateNCD(_ncd, _policyId);

        Policy memory selectedPolicy = policies[_policyId];
        uint256 premiumAmount = calculatePremium(_policyId, _ncd, _carAge, selectedPolicy.carBrandFactor);
        
        require(msg.value >= premiumAmount, "Incorrect premium amount.");

        // Register user and set the year they paid the premium
        users[msg.sender] = User({
            userAddress: msg.sender,
            ncd: _ncd,
            premiumPaid: msg.value,
            registered: true,
            lastPaymentYear: block.timestamp,
            hasClaimed: false,
            policyId: _policyId,
            carType: _carType,
            carAge: _carAge,
            carBrand: _carBrand
        });

        // Allocate premium funds to respective pools
        allocatePremiumFunds(msg.value);

        // Emit an event upon successful registration
        emit UserRegistered(msg.sender, _policyId, msg.value, _ncd, _carType, _carAge, _carBrand);
        transactions.push(Transaction({
            policyId: _policyId,
            ncd: _ncd,
            premiumAmount: premiumAmount,
            user: msg.sender,
            timestamp: block.timestamp
        }));
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

    // Add new policy (only by the insurance company)
    function addPolicy(
        string memory _name,
        uint256 _premiumAmount,
        uint256 _baseNCD,
        uint256 _carAgeFactor,
        uint256 _carBrandFactor,
        uint256 _claimResetNCD
    ) public onlyInsuranceCompany {
        policies[policyCount] = Policy(
            _name,
            _premiumAmount, 
            _baseNCD, 
            _carAgeFactor, 
            _carBrandFactor, 
            _claimResetNCD, 
            true
        );
        policyCount++;
    }

    // Reset the user's NCD after a claim
    function resetNCD(address _userAddress) internal {
        users[_userAddress].ncd = policies[0].claimResetNCD;  // Reset NCD based on the policy
    }

            // Function to return details of a specific policy
        function getPolicy(uint256 _policyId) public view returns (string memory, uint256, uint256, uint256, bool) {
            Policy memory policy = policies[_policyId];
            return (policy.name, policy.premiumAmount, policy.baseNCD, policy.claimResetNCD, policy.active);
        }

        // Function to return the total number of policies
        function getPolicyCount() public view returns (uint256) {
            return policyCount;
        }

        //function to retrieve total premium pool
        function getTotalPremiumPool() public view returns (uint256) {
            return totalPremiumPool;
        }

        //function to retrieve transaction history
        function getTransaction(uint256 _index) public view returns (Transaction memory) {
            require(_index < transactions.length, "Transaction does not exist");
            return transactions[_index];
        }

        function getTransactionCount() public view returns (uint256) {
            return transactions.length;
        }


    // Fallback function to receive ether
    receive() external payable {}
}
