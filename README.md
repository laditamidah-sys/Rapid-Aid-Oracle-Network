# 🆘 Rapid Aid Oracle Network

A decentralized emergency response system on Stacks blockchain that enables rapid, verified distribution of aid during emergencies through a network of trusted oracles.

## ✨ Features

### 🚨 Emergency Reporting
- **Multi-type Emergencies**: Natural disasters, medical, humanitarian, infrastructure
- **Severity Classification**: 10-point severity scale for prioritization
- **Location Tracking**: Precise geographical coordination
- **Real-time Status**: Track emergencies from report to completion

### 👥 Oracle Network
- **Bonded Verification**: Oracles stake STX to ensure reliability
- **Specialization System**: Oracles specialize in specific emergency types
- **Reputation Scoring**: Dynamic reputation based on verification accuracy
- **Reward Distribution**: Earn rewards for accurate emergency verification

### 💰 Aid Distribution
- **Threshold Verification**: Requires minimum 3 oracle confirmations
- **Graduated Funding**: Aid amount based on verification confidence
- **Transparent Distribution**: Full audit trail for all aid disbursements
- **Emergency Pool**: Community-funded aid reserves

### 🔐 Security Features
- **Bond Requirements**: 5 STX minimum bond for oracle registration
- **Cooldown Periods**: Prevent oracle spam and manipulation
- **Multi-signature Verification**: Multiple independent verifications required
- **Evidence Hashing**: Cryptographic evidence storage

## 🚀 Quick Start

### Register as Oracle
```clarity
(contract-call? .rapid-aid-oracle-network register-oracle u0 u5000000)
```
Register as a natural disaster oracle with 5 STX bond.

### Report Emergency
```clarity
(contract-call? .rapid-aid-oracle-network report-emergency 
    "Tokyo, Japan" 
    u0 
    u8 
    u10000000
    "Major earthquake damage to residential area")
```
Report a severe natural disaster emergency requesting 10 STX aid.

### Verify Emergency
```clarity
(contract-call? .rapid-aid-oracle-network verify-emergency 
    u1 
    true 
    u95 
    "evidence-hash-abc123")
```
Verify emergency ID 1 with 95% confidence.

### Fund Emergency Pool
```clarity
(contract-call? .rapid-aid-oracle-network fund-emergency-pool u5000000)
```
Contribute 5 STX to the emergency aid fund.

## 🏗️ Contract Architecture

### Emergency Types
- `u0` Natural Disaster (earthquakes, floods, hurricanes)
- `u1` Medical Emergency (disease outbreaks, medical supply shortages)
- `u2` Humanitarian Crisis (refugee situations, conflict zones)
- `u3` Infrastructure Damage (power grid, transportation failures)

### Emergency Status Flow
1. **Pending** → Emergency reported, awaiting verification
2. **Verified** → Confirmed by oracle network, ready for funding
3. **Funded** → Aid distributed to reporter
4. **Completed** → Emergency resolved with evidence
5. **Rejected** → Emergency determined invalid by oracles

### Aid Calculation
- **5+ Verifications**: 100% of requested amount
- **4 Verifications**: 90% of requested amount  
- **3 Verifications**: 75% of requested amount
- **<3 Verifications**: No aid distributed

## 📊 System Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| Min Aid Amount | 1 STX | Minimum emergency aid request |
| Max Aid Amount | 100 STX | Maximum emergency aid request |
| Oracle Bond | 5 STX | Minimum bond for oracle registration |
| Verification Threshold | 3 | Minimum verifications for approval |
| Cooldown Period | 144 blocks | Time between oracle verifications |
| Oracle Reward Rate | 5% | Percentage of aid as oracle rewards |

## 🧪 Testing

The contract includes comprehensive test coverage:

```bash
# Install dependencies
npm install

# Run all tests
npm test

# Test specific functionality
npm run test:emergency    # Emergency reporting and verification
npm run test:oracle       # Oracle registration and management
npm run test:funding      # Aid distribution and funding
npm run test:reputation   # Oracle reputation system
```

## 📈 Network Statistics

Track key performance indicators:

- **📊 Total Emergencies**: Number of reported emergencies
- **👥 Active Oracles**: Currently registered verification oracles
- **💵 Aid Distributed**: Total STX distributed as emergency aid
- **🏦 Fund Balance**: Current emergency pool reserves
- **⚡ Response Time**: Average verification to funding time

## 🔍 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 401 | ERR_UNAUTHORIZED | Caller lacks required permissions |
| 402 | ERR_ORACLE_NOT_FOUND | Oracle not registered in network |
| 403 | ERR_INVALID_AMOUNT | Invalid amount parameter |
| 404 | ERR_EMERGENCY_NOT_FOUND | Emergency ID not found |
| 405 | ERR_ALREADY_VERIFIED | Oracle already verified this emergency |
| 406 | ERR_INSUFFICIENT_FUNDS | Not enough funds in emergency pool |
| 407 | ERR_INVALID_STATUS | Invalid emergency or oracle status |
| 408 | ERR_ORACLE_INACTIVE | Oracle is deactivated |
| 410 | ERR_COOLDOWN_ACTIVE | Oracle cooldown period active |

## 🌍 Real-World Applications

### Natural Disaster Response
- Earthquake relief coordination
- Flood damage assessment
- Hurricane evacuation funding
- Wildfire emergency supplies

### Medical Emergency Support  
- Disease outbreak response
- Medical supply distribution
- Healthcare worker support
- Emergency medical transportation

### Humanitarian Crisis Aid
- Refugee assistance programs
- Conflict zone relief efforts
- Food security emergencies
- Displacement support services

## 🤝 Contributing

We welcome contributions from the emergency response and blockchain communities!

### Development Process
1. Fork the repository
2. Create feature branch: `git checkout -b feature/emergency-enhancement`
3. Make changes with comprehensive tests
4. Run full test suite: `npm test`
5. Submit pull request with detailed description

### Code Standards
- Follow Clarity best practices
- Include comprehensive test coverage
- Document all public functions
- Ensure security review for critical functions

## 🛡️ Security Considerations

### Oracle Security
- **Bond Slashing**: Malicious oracles lose staked funds
- **Reputation Penalties**: False verifications reduce oracle reputation
- **Cooldown Enforcement**: Prevent rapid-fire manipulative verifications

### Emergency Validation
- **Multi-source Verification**: Require multiple independent confirmations
- **Evidence Requirements**: Cryptographic proof of emergency conditions
- **Time-based Validation**: Emergency reports must be recent and relevant

### Fund Protection
- **Threshold Requirements**: Prevent single-oracle fund drainage
- **Amount Limits**: Cap individual emergency aid requests
- **Audit Trails**: Complete transparency for all fund movements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Emergency Contact

For critical issues or emergency situations:
- **Discord**: [Emergency Response Channel]
- **Telegram**: [@RapidAidNetwork]
- **Email**: emergency@rapidaid.network

---

**Built with ❤️ for humanity's resilience in times of crisis**

*Together, we can respond faster and help more effectively through decentralized emergency coordination.*
