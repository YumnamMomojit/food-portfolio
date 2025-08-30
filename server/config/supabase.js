import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Supabase configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Environment variables check:');
  console.error('SUPABASE_URL:', supabaseUrl ? 'Set' : 'Missing');
  console.error('SUPABASE_ANON_KEY:', supabaseKey ? 'Set' : 'Missing');
  console.error('SUPABASE_SERVICE_ROLE_KEY:', supabaseServiceKey ? 'Set' : 'Missing');
  throw new Error('Missing Supabase environment variables. Please check your .env file.');
}

// Create Supabase client for general operations
const supabase = createClient(supabaseUrl, supabaseKey);

// Create Supabase client with service role for admin operations
const supabaseAdmin = supabaseServiceKey 
  ? createClient(supabaseUrl, supabaseServiceKey)
  : null;

// Test connection function
const testConnection = async () => {
  try {
    // First test basic connection
    const { data, error } = await supabase
      .from('dishes')
      .select('count', { count: 'exact', head: true });
    
    if (error) {
      if (error.message.includes('relation "dishes" does not exist')) {
        console.warn('⚠️  Database tables not found. Please run the SQL schema in your Supabase dashboard.');
        console.warn('📝 Copy the contents of server/database/schema.sql and run it in the SQL Editor.');
        return false;
      }
      console.warn('⚠️  Supabase connection test failed:', error.message);
      return false;
    }
    
    console.log('✅ Supabase connection successful');
    console.log('📊 Database tables are ready');
    return true;
  } catch (err) {
    console.warn('⚠️  Supabase connection error:', err.message);
    return false;
  }
};

// Database helper functions
const dbHelpers = {
  // Generic select function
  select: async (table, columns = '*', filters = {}) => {
    try {
      let query = supabase.from(table).select(columns);
      
      // Apply filters
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          query = query.eq(key, value);
        }
      });
      
      const { data, error } = await query;
      
      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error(`Error selecting from ${table}:`, error);
      return { data: null, error };
    }
  },

  // Generic insert function
  insert: async (table, data) => {
    try {
      const { data: result, error } = await supabase
        .from(table)
        .insert(data)
        .select();
      
      if (error) throw error;
      return { data: result, error: null };
    } catch (error) {
      console.error(`Error inserting into ${table}:`, error);
      return { data: null, error };
    }
  },

  // Generic update function
  update: async (table, id, data) => {
    try {
      const { data: result, error } = await supabase
        .from(table)
        .update(data)
        .eq('id', id)
        .select();
      
      if (error) throw error;
      return { data: result, error: null };
    } catch (error) {
      console.error(`Error updating ${table}:`, error);
      return { data: null, error };
    }
  },

  // Generic delete function
  delete: async (table, id) => {
    try {
      const { error } = await supabase
        .from(table)
        .delete()
        .eq('id', id);
      
      if (error) throw error;
      return { error: null };
    } catch (error) {
      console.error(`Error deleting from ${table}:`, error);
      return { error };
    }
  }
};

export {
  supabase,
  supabaseAdmin,
  testConnection,
  dbHelpers
};