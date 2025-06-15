# Abstract L2 Deployment Guide

## Network Configuration

### Mainnet
- RPC URL: https://api.abs.xyz
- Chain ID: 11124
- Block Explorer: https://explorer.abs.xyz
- Gas Token: ETH

### Testnet
- RPC URL: https://api.testnet.abs.xyz
- Chain ID: 11125
- Block Explorer: https://testnet.explorer.abs.xyz
- Faucet: https://faucet.abs.xyz

## Deployment Steps

1. **Configure Environment**
   ```bash
   export ABSTRACT_RPC=https://api.abs.xyz
   export PRIVATE_KEY=your_deployment_key
   ```

2. **Fund Deployer**
   - Required: ~0.1 ETH for deployment
   - Buffer: 0.05 ETH for post-deployment config

3. **Deploy Contract**
   ```bash
   pnpm deploy:mainnet
   ```

4. **Verify Contract**
   - Automatic verification via script
   - Manual: Use Abstract block explorer

5. **Post-Deployment**
   - Transfer ownership to multi-sig
   - Set merkle root
   - Configure base URI
   - Enable appropriate mint phase

## Gas Optimization

Abstract L2 offers significantly lower gas costs:
- Deploy: ~0.002 ETH
- Mint: ~0.0001 ETH
- Vote: ~0.00005 ETH

## Best Practices

1. Always deploy to testnet first
2. Verify all functions work correctly
3. Monitor gas prices before mainnet deployment
4. Have emergency pause ready
5. Keep deployment keys secure
