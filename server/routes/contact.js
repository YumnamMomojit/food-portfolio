import express from 'express';
import contactController from '../controllers/contactController.js';

const router = express.Router();

// Public routes
router.post('/', contactController.submitContact);

// Admin routes (you may want to add authentication middleware here)
router.get('/', contactController.getAllMessages);
router.get('/stats', contactController.getContactStats);
router.get('/recent', contactController.getRecentMessages);
router.get('/search', contactController.searchMessages);
router.get('/:id', contactController.getMessageById);
router.put('/:id/status', contactController.updateMessageStatus);
router.delete('/:id', contactController.deleteMessage);

export default router;