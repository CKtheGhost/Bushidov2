import { WebClient } from '@slack/web-api';
import pino from 'pino';

const logger = pino();
const slack = new WebClient(process.env.SLACK_BOT_TOKEN);

interface Alert {
  severity: 'info' | 'warning' | 'critical';
  title: string;
  message: string;
  context?: Record<string, any>;
}

export class AlertManager {
  private readonly channelId = process.env.SLACK_ALERT_CHANNEL || '';
  
  async sendAlert(alert: Alert) {
    const color = {
      info: '#36a64f',
      warning: '#ff9900',
      critical: '#ff0000',
    }[alert.severity];
    
    try {
      await slack.chat.postMessage({
        channel: this.channelId,
        attachments: [
          {
            color,
            title: alert.title,
            text: alert.message,
            fields: alert.context
              ? Object.entries(alert.context).map(([key, value]) => ({
                  title: key,
                  value: String(value),
                  short: true,
                }))
              : undefined,
            ts: String(Date.now() / 1000),
          },
        ],
      });
    } catch (error) {
      logger.error({ error }, 'Failed to send Slack alert');
    }
  }
  
  async criticalAlert(title: string, message: string, context?: Record<string, any>) {
    await this.sendAlert({
      severity: 'critical',
      title,
      message,
      context,
    });
  }
  
  setupContractMonitoring(contract: any) {
    // Monitor critical contract events
    contract.on('EmergencyPause', async () => {
      await this.criticalAlert(
        'Contract Paused',
        'The Bushido NFT contract has been paused',
        { timestamp: new Date().toISOString() }
      );
    });
    
    contract.on('OwnershipTransferred', async (previousOwner: string, newOwner: string) => {
      await this.criticalAlert(
        'Ownership Transferred',
        `Contract ownership transferred from ${previousOwner} to ${newOwner}`,
        { previousOwner, newOwner }
      );
    });
  }
}
