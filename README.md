A decentralized platform for leasing mining equipment powered by Clarity smart contracts on the Stacks blockchain.

## 🚀 Features

- 🏗️ **Equipment Registration**: Register mining equipment with GPS coordinates
- 🔄 **Equipment Ownership Transfer**: Seamless transfer of equipment ownership between principals
- 💰 **Escrow System**: Secure rental payments with automatic escrow
- 📍 **GPS Tracking**: Track leased equipment location in real-time
- ⚖️ **DAO Dispute Resolution**: Community-driven dispute resolution through voting
- 🔒 **Secure Leasing**: Trustless equipment leasing with smart contract protection
- ⭐ **Equipment Rating System**: Lessees can rate equipment after lease completion
- 🏁 **Early Lease Termination**: Allow lessees to terminate leases prematurely with a penalty fee

## 🏁 Quick Start

### Deploy the Contract

```bash
clarinet deploy
```

### Register Equipment

```bash
(contract-call? .Mining-Equipment-Leasing-Marketplace register-equipment 
  "Excavator CAT 320" 
  u500000 
  40742421 
  -73985664)
```

### Create a Lease

```bash
(contract-call? .Mining-Equipment-Leasing-Marketplace create-lease u1 u7)
```

### Complete a Lease

```bash
(contract-call? .Mining-Equipment-Leasing-Marketplace complete-lease u1)
```

## 📋 Core Functions

### 🏗️ Equipment Management
- `transfer-equipment-ownership` - Transfer ownership of equipment to another principal
- `register-equipment` - Register new mining equipment
- `update-equipment-location` - Update GPS coordinates
- `get-equipment` - View equipment details
- `rate-equipment` - Rate equipment after lease completion
- `get-equipment-rating` - View equipment rating details

### 🤝 Leasing
- `create-lease` - Create new equipment lease
- `complete-lease` - Complete active lease
- `terminate-lease-early` - Terminate lease early with penalty
- `get-lease` - View lease details

### ⚖️ Dispute Resolution
- `create-dispute` - Create dispute for active lease
- `vote-dispute` - Vote on dispute resolution
- `resolve-dispute` - Resolve dispute based on votes

### 💰 Escrow
- `get-escrow` - Check escrow status

## 🔧 Usage Examples

### Equipment Owner Workflow
6. Transfer equipment ownership if needed
1. Register equipment with location
2. Wait for lease requests
3. Receive automatic payment after lease completion

### Equipment Renter Workflow
1. Find available equipment
2. Create lease with escrow payment
3. Use equipment during lease period
3.5 Terminate lease early if needed (with penalty)
4. Complete lease to release payment
5. Rate equipment to provide feedback

### Dispute Resolution
1. Create dispute if issues arise
2. Community votes on resolution
3. Automatic resolution based on majority vote

## 📊 Data Structures

- **Equipment**: ID, owner, name, daily rate, availability, GPS location
- **Lease**: Equipment ID, parties, duration, escrow amount, status
- **Dispute**: Lease ID, description, votes, resolution status
- **Escrow**: Amount, release status
- **Equipment Rating**: Total rating, rating count

## 🌐 GPS Coordinates

Coordinates use integer format with 6 decimal places precision:
- Latitude: -90000000 to 90000000 (-90.0 to 90.0 degrees)
- Longitude: -180000000 to 180000000 (-180.0 to 180.0 degrees)

- ✅ Equipment ownership transfer with availability checks
## 🛡️ Security Features

- ✅ Owner verification for equipment updates
- ✅ Escrow protection for payments
- ✅ Community-driven dispute resolution
- ✅ GPS coordinate validation
- ✅ Lease duration and amount validation
- ✅ Rating validation and duplicate prevention
- ✅ Early termination with penalty enforcement

## 🎯 Error Codes

- `u100` - Unauthorized access
- `u101` - Equipment not found
- `u102` - Lease not found
- `u103` - Invalid amount
- `u104` - Lease already active
- `u105` - Lease not active
- `u106` - Payment failed
- `u107` - Dispute already exists
- `u108` - Dispute not found
- `u109` - Already voted
- `u110` - Invalid coordinates
- `u111` - Invalid rating
- `u112` - Already rated

## 🚀 Deployment

This contract is ready for deployment on Stacks testnet/mainnet using Clarinet.
