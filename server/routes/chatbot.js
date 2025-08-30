import express from 'express';
import chatbotController from '../controllers/chatbotController.js';

const router = express.Router();

// Main chat endpoint
router.post('/chat', chatbotController.chat);

// Specialized AI features
router.post('/recommend', chatbotController.getFoodRecommendation);
router.post('/cooking-tip', chatbotController.getCookingTip);

// System endpoints
router.get('/status', chatbotController.getStatus);
router.get('/test', chatbotController.testAI);
router.get('/history', chatbotController.getConversationHistory);

export default router;