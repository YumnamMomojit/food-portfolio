import DishModel from '../models/Dish.js';

class PortfolioController {
  // Get all dishes
  async getAllDishes(req, res) {
    try {
      const { category, featured, available, search } = req.query;
      
      let result;
      
      if (search) {
        result = await DishModel.search(search);
      } else if (featured === 'true') {
        result = await DishModel.getFeatured();
      } else if (available === 'true') {
        result = await DishModel.getAvailable();
      } else if (category) {
        result = await DishModel.getByCategory(category);
      } else {
        result = await DishModel.getAll();
      }

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error fetching dishes',
          error: result.error.message
        });
      }

      res.status(200).json({
        success: true,
        data: result.data || [],
        count: result.data ? result.data.length : 0
      });
    } catch (error) {
      console.error('Error in getAllDishes:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Get single dish by ID
  async getDishById(req, res) {
    try {
      const { id } = req.params;
      
      const result = await DishModel.getById(id);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error fetching dish',
          error: result.error.message
        });
      }

      if (!result.data) {
        return res.status(404).json({
          success: false,
          message: 'Dish not found'
        });
      }

      res.status(200).json({
        success: true,
        data: result.data
      });
    } catch (error) {
      console.error('Error in getDishById:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Create new dish
  async createDish(req, res) {
    try {
      const dishData = req.body;

      // Validation
      if (!dishData.title || !dishData.description || !dishData.category) {
        return res.status(400).json({
          success: false,
          message: 'Title, description, and category are required'
        });
      }

      const result = await DishModel.create(dishData);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error creating dish',
          error: result.error.message
        });
      }

      res.status(201).json({
        success: true,
        message: 'Dish created successfully',
        data: result.data[0]
      });
    } catch (error) {
      console.error('Error in createDish:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Update dish
  async updateDish(req, res) {
    try {
      const { id } = req.params;
      const dishData = req.body;

      const result = await DishModel.update(id, dishData);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error updating dish',
          error: result.error.message
        });
      }

      if (!result.data || result.data.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Dish not found'
        });
      }

      res.status(200).json({
        success: true,
        message: 'Dish updated successfully',
        data: result.data[0]
      });
    } catch (error) {
      console.error('Error in updateDish:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Delete dish
  async deleteDish(req, res) {
    try {
      const { id } = req.params;

      const result = await DishModel.delete(id);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error deleting dish',
          error: result.error.message
        });
      }

      res.status(200).json({
        success: true,
        message: 'Dish deleted successfully'
      });
    } catch (error) {
      console.error('Error in deleteDish:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Get dish categories
  async getCategories(req, res) {
    try {
      const categories = [
        { id: 'appetizers', name: 'Appetizers', description: 'Start your meal with these delicious options' },
        { id: 'mains', name: 'Main Courses', description: 'Our signature main dishes' },
        { id: 'desserts', name: 'Desserts', description: 'Sweet endings to your perfect meal' },
        { id: 'drinks', name: 'Beverages', description: 'Refreshing drinks and specialty cocktails' },
        { id: 'specials', name: 'Chef Specials', description: 'Limited time seasonal offerings' }
      ];

      res.status(200).json({
        success: true,
        data: categories
      });
    } catch (error) {
      console.error('Error in getCategories:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Get portfolio statistics
  async getStats(req, res) {
    try {
      const [allDishes, featuredDishes, availableDishes] = await Promise.all([
        DishModel.getAll(),
        DishModel.getFeatured(),
        DishModel.getAvailable()
      ]);

      const stats = {
        total_dishes: allDishes.data ? allDishes.data.length : 0,
        featured_dishes: featuredDishes.data ? featuredDishes.data.length : 0,
        available_dishes: availableDishes.data ? availableDishes.data.length : 0,
        categories: {
          appetizers: 0,
          mains: 0,
          desserts: 0,
          drinks: 0,
          specials: 0
        }
      };

      // Count dishes by category
      if (allDishes.data) {
        allDishes.data.forEach(dish => {
          if (stats.categories[dish.category] !== undefined) {
            stats.categories[dish.category]++;
          }
        });
      }

      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Error in getStats:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }
}

const portfolioController = new PortfolioController();
export default portfolioController;