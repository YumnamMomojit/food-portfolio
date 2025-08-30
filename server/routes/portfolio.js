import express from 'express';
import portfolioController from '../controllers/portfolioController.js';

const router = express.Router();

// Portfolio/Dishes routes
router.get('/', portfolioController.getAllDishes);
router.get('/stats', portfolioController.getStats);
router.get('/categories', portfolioController.getCategories);
router.get('/:id', portfolioController.getDishById);

// Admin routes (you may want to add authentication middleware here)
router.post('/', portfolioController.createDish);
router.put('/:id', portfolioController.updateDish);
router.delete('/:id', portfolioController.deleteDish);

export default router;