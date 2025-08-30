import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

console.log('🔧 Testing Supabase Connection...');
console.log('Environment check:');
console.log('SUPABASE_URL:', process.env.SUPABASE_URL ? '✅ Set' : '❌ Missing');
console.log('SUPABASE_ANON_KEY:', process.env.SUPABASE_ANON_KEY ? '✅ Set' : '❌ Missing');

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
  console.error('❌ Missing environment variables');
  process.exit(1);
}

// Create Supabase client
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Test connection
async function testConnection() {
  try {
    console.log('\n🚀 Testing Supabase connection...');
    
    // Try to access dishes table
    const { data, error } = await supabase
      .from('dishes')
      .select('count', { count: 'exact', head: true });
    
    if (error) {
      if (error.message.includes('relation "dishes" does not exist')) {
        console.log('⚠️  Database tables not found.');
        console.log('📝 You need to run the SQL schema in your Supabase dashboard:');
        console.log('   1. Go to SQL Editor in Supabase');
        console.log('   2. Copy contents of server/database/schema.sql');
        console.log('   3. Paste and run the script');
        return false;
      }
      console.error('❌ Connection error:', error.message);
      return false;
    }
    
    console.log('✅ Supabase connection successful!');
    
    // Try to fetch some data
    const { data: dishes, error: fetchError } = await supabase
      .from('dishes')
      .select('*')
      .limit(3);
    
    if (fetchError) {
      console.error('❌ Error fetching data:', fetchError.message);
      return false;
    }
    
    console.log(`📊 Found ${dishes.length} sample dishes in database`);
    if (dishes.length > 0) {
      console.log('Sample dish:', dishes[0].title);
    }
    
    return true;
  } catch (err) {
    console.error('❌ Unexpected error:', err.message);
    return false;
  }
}

testConnection().then(success => {
  if (success) {
    console.log('\n🎉 Supabase integration is working!');
    console.log('You can now start your server with: npm run server:dev');
  } else {
    console.log('\n🔧 Please fix the issues above and try again.');
  }
  process.exit(success ? 0 : 1);
});