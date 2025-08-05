# Decentralized Public Works and Infrastructure Maintenance System

A blockchain-based system for managing municipal infrastructure maintenance using Clarity smart contracts on the Stacks blockchain.

## Overview

This system provides decentralized coordination for public works departments to manage:
- Pothole reporting and repair tracking
- Snow removal operations coordination
- Tree maintenance and removal scheduling
- Sidewalk repair monitoring
- Public building maintenance management

## Architecture

The system consists of five independent Clarity smart contracts:

### 1. Pothole Management Contract (`pothole-management.clar`)
- Citizens can report potholes with location and severity
- Repair crews can claim and update repair status
- Tracks completion and quality ratings

### 2. Snow Removal Contract (`snow-removal.clar`)
- Manages snow plowing routes and priorities
- Coordinates salt distribution
- Tracks equipment deployment during winter storms

### 3. Tree Maintenance Contract (`tree-maintenance.clar`)
- Schedules tree pruning and removal
- Tracks safety inspections
- Manages contractor assignments

### 4. Sidewalk Repair Contract (`sidewalk-repair.clar`)
- Monitors sidewalk conditions
- Prioritizes accessibility improvements
- Tracks repair completion

### 5. Public Building Maintenance Contract (`public-building-maintenance.clar`)
- Manages facility repair requests
- Tracks maintenance schedules
- Coordinates contractor work

## Key Features

- **Decentralized Reporting**: Citizens can directly report issues
- **Transparent Tracking**: All maintenance activities are publicly visible
- **Automated Prioritization**: Smart contracts handle priority assignment
- **Contractor Coordination**: Streamlined work assignment system
- **Quality Assurance**: Built-in rating and feedback mechanisms

## Data Structures

Each contract uses standardized data structures for:
- Issue reporting with location coordinates
- Status tracking (reported, assigned, in-progress, completed)
- Priority levels (low, medium, high, emergency)
- Contractor/crew management
- Cost tracking and budgeting

## Getting Started

1. Install dependencies: \`npm install\`
2. Run tests: \`npm test\`
3. Deploy contracts using Clarinet: \`clarinet deploy\`

## Testing

The system includes comprehensive tests using Vitest to verify:
- Contract deployment and initialization
- Issue reporting functionality
- Status updates and transitions
- Access control and permissions
- Data integrity and validation

## Usage Examples

### Reporting a Pothole
\`\`\`clarity
(contract-call? .pothole-management report-pothole
u40750000 u-73980000 u3 "Large pothole on Main St")
\`\`\`

### Assigning Snow Removal Route
\`\`\`clarity
(contract-call? .snow-removal assign-route
u1 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNP)
\`\`\`

## Contract Addresses

After deployment, contract addresses will be available in the deployment receipts.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
