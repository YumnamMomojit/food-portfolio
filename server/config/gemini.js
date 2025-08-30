import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

class GeminiService {
  constructor() {
    this.apiKey = process.env.GEMINI_API_KEY;
    
    if (!this.apiKey) {
      console.warn('⚠️  Gemini API key not found. Please add GEMINI_API_KEY to your .env file.');
      this.genAI = null;
    } else {
      this.genAI = new GoogleGenerativeAI(this.apiKey);
      this.model = this.genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
      console.log('✅ Gemini AI service initialized');
    }
  }

  // Check if Gemini service is available
  isAvailable() {
    return this.genAI !== null;
  }

  // Generate response with food portfolio context
  async generateResponse(message, portfolioContext = null) {
    if (!this.isAvailable()) {
      throw new Error('Gemini AI service is not available. Please check your API key.');
    }

    try {
      // Create context-aware prompt
      const systemContext = `
You are a helpful AI assistant for "Culinary Creations", a premium food portfolio website. 
Your role is to help customers with:
- Information about our dishes and menu items
- Culinary advice and cooking tips
- Event planning and catering inquiries
- Food recommendations based on preferences
- General information about our services

Always be friendly, professional, and knowledgeable about food and cooking.
If asked about specific dishes, refer to the portfolio context provided.
If you don't know something specific about our business, politely redirect them to contact us directly.
`;

      let contextPrompt = systemContext;
      
      // Add portfolio context if available
      if (portfolioContext && portfolioContext.length > 0) {
        contextPrompt += `\n\nOur Current Menu Items:\n`;
        portfolioContext.forEach(dish => {
          contextPrompt += `- ${dish.title}: ${dish.description} (${dish.category})\n`;
        });
      }

      contextPrompt += `\n\nCustomer Question: ${message}`;

      const result = await this.model.generateContent(contextPrompt);
      const response = await result.response;
      const text = response.text();

      return {
        success: true,
        message: text,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Gemini API Error:', error);
      
      // Handle different types of errors
      if (error.message?.includes('API_KEY_INVALID')) {
        throw new Error('Invalid Gemini API key. Please check your configuration.');
      } else if (error.message?.includes('RATE_LIMIT_EXCEEDED')) {
        throw new Error('Rate limit exceeded. Please try again later.');
      } else {
        throw new Error('Failed to generate response. Please try again.');
      }
    }
  }

  // Generate food-specific recommendations
  async generateFoodRecommendation(preferences, dietaryRestrictions = []) {
    if (!this.isAvailable()) {
      throw new Error('Gemini AI service is not available.');
    }

    try {
      const prompt = `
As a culinary expert for Culinary Creations, recommend dishes based on these preferences:
- Customer preferences: ${preferences}
- Dietary restrictions: ${dietaryRestrictions.length > 0 ? dietaryRestrictions.join(', ') : 'None'}

Please provide 2-3 specific dish recommendations with brief descriptions.
Focus on dishes that would fit our upscale food portfolio.
Be creative but realistic for a premium restaurant.
`;

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      return {
        success: true,
        recommendations: text,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Food recommendation error:', error);
      throw new Error('Failed to generate food recommendations.');
    }
  }

  // Generate cooking tips
  async generateCookingTip(topic) {
    if (!this.isAvailable()) {
      throw new Error('Gemini AI service is not available.');
    }

    try {
      const prompt = `
As a professional chef from Culinary Creations, provide a helpful cooking tip about: ${topic}

Make it practical, professional, and suitable for both home cooks and culinary enthusiasts.
Keep it concise but informative.
`;

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      return {
        success: true,
        tip: text,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Cooking tip error:', error);
      throw new Error('Failed to generate cooking tip.');
    }
  }

  // Test the connection
  async testConnection() {
    if (!this.isAvailable()) {
      return {
        success: false,
        message: 'Gemini API key not configured'
      };
    }

    try {
      const result = await this.model.generateContent('Hello! Please respond with a brief greeting.');
      const response = await result.response;
      const text = response.text();

      return {
        success: true,
        message: 'Gemini AI connection successful',
        testResponse: text
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to connect to Gemini AI',
        error: error.message
      };
    }
  }
}

// Create and export singleton instance
const geminiService = new GeminiService();
export default geminiService;