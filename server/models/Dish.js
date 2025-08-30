import { dbHelpers } from '../config/supabase.js';

class DishModel {
  constructor() {
    this.tableName = 'dishes';
  }

  // Get all dishes with optional category filter
  async getAll(category = null) {
    const filters = category ? { category } : {};
    return await dbHelpers.select(this.tableName, '*', filters);
  }

  // Get dish by ID
  async getById(id) {
    const result = await dbHelpers.select(this.tableName, '*', { id });
    return {
      data: result.data ? result.data[0] : null,
      error: result.error
    };
  }

  // Create new dish
  async create(dishData) {
    const dish = {
      title: dishData.title,
      description: dishData.description,
      category: dishData.category,
      image_url: dishData.image_url || null,
      price: dishData.price || null,
      ingredients: dishData.ingredients || [],
      is_featured: dishData.is_featured || false,
      is_available: dishData.is_available !== false, // Default to true
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    return await dbHelpers.insert(this.tableName, dish);
  }

  // Update dish
  async update(id, dishData) {
    const updateData = {
      ...dishData,
      updated_at: new Date().toISOString()
    };

    return await dbHelpers.update(this.tableName, id, updateData);
  }

  // Delete dish
  async delete(id) {
    return await dbHelpers.delete(this.tableName, id);
  }

  // Get dishes by category
  async getByCategory(category) {
    return await dbHelpers.select(this.tableName, '*', { category });
  }

  // Get featured dishes
  async getFeatured() {
    return await dbHelpers.select(this.tableName, '*', { is_featured: true });
  }

  // Get available dishes
  async getAvailable() {
    return await dbHelpers.select(this.tableName, '*', { is_available: true });
  }

  // Search dishes by title or description
  async search(searchTerm) {
    try {
      const { supabase } = await import('../config/supabase.js');
      const { data, error } = await supabase
        .from(this.tableName)
        .select('*')
        .or(`title.ilike.%${searchTerm}%,description.ilike.%${searchTerm}%`);

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error searching dishes:', error);
      return { data: null, error };
    }
  }
}

const dishModel = new DishModel();
export default dishModel;