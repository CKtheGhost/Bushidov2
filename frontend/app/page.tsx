import { CountdownTimer } from '../src/components/countdown/CountdownTimer'

export default function Home() {
  const nextMint = new Date(Date.now() + 86400000)
  return (
    <main>
      <h1>Bushido NFT</h1>
      <p>Welcome to the community-driven anime.</p>
      <CountdownTimer targetDate={nextMint} />
    </main>
  )
}
