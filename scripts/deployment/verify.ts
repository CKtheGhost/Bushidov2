import { run } from 'hardhat';

export async function verify(contractAddress: string, args: any[]) {
  try {
    await run('verify:verify', {
      address: contractAddress,
      constructorArguments: args,
    });
    console.log('✅ Contract verified successfully');
  } catch (error: any) {
    if (error.message.toLowerCase().includes('already verified')) {
      console.log('✅ Contract already verified');
    } else {
      console.error('❌ Verification failed:', error);
    }
  }
}
