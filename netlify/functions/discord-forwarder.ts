import { Handler } from "@netlify/functions";
import axios from "axios";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

// Define interface for the expected payload
interface DiscordPayload {
  message: string;
  username?: string;
  avatarUrl?: string;
  webhookUrl?: string;
}

// Define interface for Discord request body
interface DiscordWebhookPayload {
  content: string;
  username: string;
  avatar_url?: string;
}

export const handler: Handler = async (event, context) => {
  // Only allow POST requests
  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: "Method Not Allowed" }),
    };
  }

  try {
    // Parse the incoming request body
    const payload = JSON.parse(event.body || "{}") as DiscordPayload;

    // Validate required fields
    if (!payload.message) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing required field: message" }),
      };
    }

    // Get the webhook URL from environment variables or from the payload
    const webhookUrl = payload.webhookUrl || process.env.DISCORD_WEBHOOK_URL;

    if (!webhookUrl) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "No Discord webhook URL provided" }),
      };
    }

    // Optional parameters
    const username =
      payload.username || process.env.DISCORD_USERNAME || "Serverless Bot";
    const avatarUrl = payload.avatarUrl || process.env.DISCORD_AVATAR_URL;

    // Prepare the Discord message payload
    const discordPayload: DiscordWebhookPayload = {
      content: payload.message,
      username: username,
    };

    if (avatarUrl) {
      discordPayload.avatar_url = avatarUrl;
    }

    // Forward the message to Discord
    const response = await axios.post(webhookUrl, discordPayload);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Message sent successfully to Discord",
        status: response.status,
      }),
    };
  } catch (error) {
    console.error("Error:", error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to send message to Discord",
        details: error instanceof Error ? error.message : "Unknown error",
      }),
    };
  }
};
