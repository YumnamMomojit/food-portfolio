import { dbHelpers } from '../config/supabase.js';

class ContactModel {
  constructor() {
    this.tableName = 'contact_messages';
  }

  // Create new contact message
  async create(contactData) {
    const contact = {
      name: contactData.name,
      email: contactData.email,
      phone: contactData.phone || null,
      event_type: contactData.eventType || null,
      guests: contactData.guests || null,
      preferred_date: contactData.date || null,
      message: contactData.message,
      status: 'new',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    return await dbHelpers.insert(this.tableName, contact);
  }

  // Get all contact messages
  async getAll(status = null) {
    const filters = status ? { status } : {};
    return await dbHelpers.select(this.tableName, '*', filters);
  }

  // Get contact message by ID
  async getById(id) {
    const result = await dbHelpers.select(this.tableName, '*', { id });
    return {
      data: result.data ? result.data[0] : null,
      error: result.error
    };
  }

  // Update contact message status
  async updateStatus(id, status) {
    const updateData = {
      status,
      updated_at: new Date().toISOString()
    };

    return await dbHelpers.update(this.tableName, id, updateData);
  }

  // Delete contact message
  async delete(id) {
    return await dbHelpers.delete(this.tableName, id);
  }

  // Get messages by status
  async getByStatus(status) {
    return await dbHelpers.select(this.tableName, '*', { status });
  }

  // Get recent messages (last 30 days)
  async getRecent(days = 30) {
    try {
      const { supabase } = await import('../config/supabase.js');
      const dateThreshold = new Date();
      dateThreshold.setDate(dateThreshold.getDate() - days);

      const { data, error } = await supabase
        .from(this.tableName)
        .select('*')
        .gte('created_at', dateThreshold.toISOString())
        .order('created_at', { ascending: false });

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error getting recent messages:', error);
      return { data: null, error };
    }
  }

  // Search messages by email or name
  async search(searchTerm) {
    try {
      const { supabase } = await import('../config/supabase.js');
      const { data, error } = await supabase
        .from(this.tableName)
        .select('*')
        .or(`name.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%`)
        .order('created_at', { ascending: false });

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error searching messages:', error);
      return { data: null, error };
    }
  }
}

const contactModel = new ContactModel();
export default contactModel;