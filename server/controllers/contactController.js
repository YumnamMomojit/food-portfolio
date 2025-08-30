import ContactModel from '../models/Contact.js';

class ContactController {
  // Submit contact form
  async submitContact(req, res) {
    try {
      const contactData = req.body;

      // Validation
      if (!contactData.name || !contactData.email || !contactData.message) {
        return res.status(400).json({
          success: false,
          message: 'Name, email, and message are required'
        });
      }

      // Basic email validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(contactData.email)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid email address'
        });
      }

      const result = await ContactModel.create(contactData);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error submitting contact form',
          error: result.error.message
        });
      }

      // Send success response (you might want to send an email notification here)
      res.status(201).json({
        success: true,
        message: 'Thank you for your message! We will get back to you soon.',
        data: {
          id: result.data[0].id,
          name: result.data[0].name,
          email: result.data[0].email,
          created_at: result.data[0].created_at
        }
      });
    } catch (error) {
      console.error('Error in submitContact:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Get all contact messages (admin only)
  async getAllMessages(req, res) {
    try {
      const { status, limit = 50, offset = 0 } = req.query;
      
      let result;
      
      if (status) {
        result = await ContactModel.getByStatus(status);
      } else {
        result = await ContactModel.getAll();
      }

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error fetching contact messages',
          error: result.error.message
        });
      }

      // Apply pagination
      const startIndex = parseInt(offset);
      const endIndex = startIndex + parseInt(limit);
      const paginatedData = result.data ? result.data.slice(startIndex, endIndex) : [];

      res.status(200).json({
        success: true,
        data: paginatedData,
        pagination: {
          total: result.data ? result.data.length : 0,
          limit: parseInt(limit),
          offset: parseInt(offset),
          has_more: result.data ? endIndex < result.data.length : false
        }
      });
    } catch (error) {
      console.error('Error in getAllMessages:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Get single message by ID (admin only)
  async getMessageById(req, res) {
    try {
      const { id } = req.params;
      
      const result = await ContactModel.getById(id);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error fetching contact message',
          error: result.error.message
        });
      }

      if (!result.data) {
        return res.status(404).json({
          success: false,
          message: 'Contact message not found'
        });
      }

      res.status(200).json({
        success: true,
        data: result.data
      });
    } catch (error) {
      console.error('Error in getMessageById:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Update message status (admin only)
  async updateMessageStatus(req, res) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      // Validate status
      const validStatuses = ['new', 'in_progress', 'completed', 'archived'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid status. Must be one of: ' + validStatuses.join(', ')
        });
      }

      const result = await ContactModel.updateStatus(id, status);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error updating message status',
          error: result.error.message
        });
      }

      if (!result.data || result.data.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Contact message not found'
        });
      }

      res.status(200).json({
        success: true,
        message: 'Message status updated successfully',
        data: result.data[0]
      });
    } catch (error) {
      console.error('Error in updateMessageStatus:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Delete message (admin only)
  async deleteMessage(req, res) {
    try {
      const { id } = req.params;

      const result = await ContactModel.delete(id);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error deleting message',
          error: result.error.message
        });
      }

      res.status(200).json({
        success: true,
        message: 'Message deleted successfully'
      });
    } catch (error) {
      console.error('Error in deleteMessage:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Get recent messages (admin only)
  async getRecentMessages(req, res) {
    try {
      const { days = 30 } = req.query;
      
      const result = await ContactModel.getRecent(parseInt(days));

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error fetching recent messages',
          error: result.error.message
        });
      }

      res.status(200).json({
        success: true,
        data: result.data || [],
        count: result.data ? result.data.length : 0,
        days: parseInt(days)
      });
    } catch (error) {
      console.error('Error in getRecentMessages:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Search messages (admin only)
  async searchMessages(req, res) {
    try {
      const { q: searchTerm } = req.query;

      if (!searchTerm) {
        return res.status(400).json({
          success: false,
          message: 'Search term is required'
        });
      }

      const result = await ContactModel.search(searchTerm);

      if (result.error) {
        return res.status(500).json({
          success: false,
          message: 'Error searching messages',
          error: result.error.message
        });
      }

      res.status(200).json({
        success: true,
        data: result.data || [],
        count: result.data ? result.data.length : 0,
        search_term: searchTerm
      });
    } catch (error) {
      console.error('Error in searchMessages:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }

  // Get contact statistics (admin only)
  async getContactStats(req, res) {
    try {
      const [allMessages, newMessages, recentMessages] = await Promise.all([
        ContactModel.getAll(),
        ContactModel.getByStatus('new'),
        ContactModel.getRecent(30)
      ]);

      const stats = {
        total_messages: allMessages.data ? allMessages.data.length : 0,
        new_messages: newMessages.data ? newMessages.data.length : 0,
        recent_messages: recentMessages.data ? recentMessages.data.length : 0,
        status_breakdown: {
          new: 0,
          in_progress: 0,
          completed: 0,
          archived: 0
        }
      };

      // Count messages by status
      if (allMessages.data) {
        allMessages.data.forEach(message => {
          if (stats.status_breakdown[message.status] !== undefined) {
            stats.status_breakdown[message.status]++;
          }
        });
      }

      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Error in getContactStats:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }
}

const contactController = new ContactController();
export default contactController;