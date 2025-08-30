import geminiService from '../config/gemini.js';
import DishModel from '../models/Dish.js';

class ChatbotController {
  // Main chat endpoint
  async chat(req, res) {
    try {
      const { message, includeContext = true } = req.body;

      if (!message || message.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Message is required'
        });
      }

      // Check if Gemini service is available
      if (!geminiService.isAvailable()) {
        return res.status(503).json({
          success: false,
          message: 'AI chatbot service is currently unavailable. Please contact us directly for assistance.'
        });
      }

      let portfolioContext = null;

      // Get portfolio context if requested
      if (includeContext) {
        try {
          const dishesResult = await DishModel.getAvailable();
          if (dishesResult.data) {
            portfolioContext = dishesResult.data.map(dish => ({
              title: dish.title,
              description: dish.description,
              category: dish.category,
              price: dish.price
            }));
          }
        } catch (contextError) {
          console.warn('Failed to load portfolio context:', contextError);
          // Continue without context
        }
      }

      // Generate AI response
      const aiResponse = await geminiService.generateResponse(message, portfolioContext);

      res.status(200).json({
        success: true,
        data: {
          userMessage: message,
          aiResponse: aiResponse.message,
          timestamp: aiResponse.timestamp,
          contextIncluded: portfolioContext !== null
        }
      });

    } catch (error) {
      console.error('Chat error:', error);
      
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to process your message. Please try again.',
        fallbackMessage: 'I apologize, but I\'m having trouble right now. Please feel free to contact us directly through our contact form for immediate assistance.'
      });
    }
  }

  // Food recommendation endpoint
  async getFoodRecommendation(req, res) {
    try {
      const { preferences, dietaryRestrictions = [] } = req.body;

      if (!preferences || preferences.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Food preferences are required'
        });
      }

      if (!geminiService.isAvailable()) {
        return res.status(503).json({
          success: false,
          message: 'Recommendation service is currently unavailable'
        });
      }

      const recommendation = await geminiService.generateFoodRecommendation(preferences, dietaryRestrictions);

      res.status(200).json({
        success: true,
        data: {
          preferences,
          dietaryRestrictions,
          recommendations: recommendation.recommendations,
          timestamp: recommendation.timestamp
        }
      });

    } catch (error) {
      console.error('Food recommendation error:', error);
      
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to generate recommendations'
      });
    }
  }

  // Cooking tip endpoint
  async getCookingTip(req, res) {
    try {
      const { topic } = req.body;

      if (!topic || topic.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Cooking topic is required'
        });
      }

      if (!geminiService.isAvailable()) {
        return res.status(503).json({
          success: false,
          message: 'Cooking tips service is currently unavailable'
        });
      }

      const tip = await geminiService.generateCookingTip(topic);

      res.status(200).json({
        success: true,
        data: {
          topic,
          tip: tip.tip,
          timestamp: tip.timestamp
        }
      });

    } catch (error) {
      console.error('Cooking tip error:', error);
      
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to generate cooking tip'
      });
    }
  }

  // Test AI connection endpoint
  async testAI(req, res) {
    try {
      const result = await geminiService.testConnection();
      
      res.status(result.success ? 200 : 503).json(result);
    } catch (error) {
      console.error('AI test error:', error);
      
      res.status(500).json({
        success: false,
        message: 'Failed to test AI connection',
        error: error.message
      });
    }
  }

  // Get chatbot status and capabilities
  async getStatus(req, res) {
    try {
      const isAvailable = geminiService.isAvailable();
      
      res.status(200).json({
        success: true,
        data: {
          aiAvailable: isAvailable,
          capabilities: [
            'General food and cooking questions',
            'Menu item information',
            'Food recommendations',
            'Cooking tips and advice',
            'Event planning assistance'
          ],
          apiStatus: isAvailable ? 'connected' : 'disconnected',
          lastUpdated: new Date().toISOString()
        }
      });
    } catch (error) {
      console.error('Status check error:', error);
      
      res.status(500).json({
        success: false,
        message: 'Failed to check chatbot status'
      });
    }
  }

  // Conversation history (placeholder for future database integration)
  async getConversationHistory(req, res) {
    try {
      // This could be extended to store conversations in database
      res.status(200).json({
        success: true,
        data: {
          conversations: [],
          message: 'Conversation history feature coming soon'
        }
      });
    } catch (error) {
      console.error('History error:', error);
      
      res.status(500).json({
        success: false,
        message: 'Failed to retrieve conversation history'
      });
    }
  }
}

const chatbotController = new ChatbotController();
export default chatbotController;