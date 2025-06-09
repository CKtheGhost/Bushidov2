import { PinataClient } from 'pinata'

export class IpfsService {
  private client: PinataClient

  constructor() {
    this.client = new PinataClient({
      pinataApiKey: process.env.PINATA_API_KEY!,
      pinataSecretApiKey: process.env.PINATA_SECRET_KEY!
    })
  }

  async uploadJSON(data: Record<string, unknown>): Promise<string> {
    const result = await this.client.pinJSONToIPFS(data)
    return result.IpfsHash
  }
}
