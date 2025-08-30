-- Food Portfolio Database Schema
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create categories enum
CREATE TYPE dish_category AS ENUM ('appetizers', 'mains', 'desserts', 'drinks', 'specials');
CREATE TYPE contact_status AS ENUM ('new', 'in_progress', 'completed', 'archived');

-- Create dishes table
CREATE TABLE IF NOT EXISTS dishes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category dish_category NOT NULL DEFAULT 'mains',
    image_url TEXT,
    price DECIMAL(10, 2),
    ingredients TEXT[], -- Array of ingredients
    is_featured BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create contact_messages table
CREATE TABLE IF NOT EXISTS contact_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    event_type VARCHAR(100),
    guests INTEGER,
    preferred_date DATE,
    message TEXT NOT NULL,
    status contact_status DEFAULT 'new',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_dishes_category ON dishes(category);
CREATE INDEX IF NOT EXISTS idx_dishes_featured ON dishes(is_featured);
CREATE INDEX IF NOT EXISTS idx_dishes_available ON dishes(is_available);
CREATE INDEX IF NOT EXISTS idx_dishes_created_at ON dishes(created_at);

CREATE INDEX IF NOT EXISTS idx_contact_status ON contact_messages(status);
CREATE INDEX IF NOT EXISTS idx_contact_email ON contact_messages(email);
CREATE INDEX IF NOT EXISTS idx_contact_created_at ON contact_messages(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_dishes_updated_at BEFORE UPDATE ON dishes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contact_messages_updated_at BEFORE UPDATE ON contact_messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for dishes
INSERT INTO dishes (title, description, category, price, ingredients, is_featured, is_available) VALUES
('Seared Salmon with Quinoa', 'Pan-seared salmon with herbed quinoa and seasonal vegetables', 'mains', 28.50, ARRAY['salmon', 'quinoa', 'vegetables', 'herbs'], true, true),
('Artisan Pasta Creation', 'Hand-crafted pasta with truffle cream sauce and parmesan', 'mains', 24.00, ARRAY['pasta', 'truffle', 'cream', 'parmesan'], true, true),
('Chocolate Lava Cake', 'Decadent chocolate cake with molten center and vanilla ice cream', 'desserts', 12.00, ARRAY['chocolate', 'vanilla ice cream', 'berries'], false, true),
('Garden Fresh Salad', 'Mixed greens with seasonal fruits and balsamic reduction', 'appetizers', 14.50, ARRAY['mixed greens', 'seasonal fruits', 'balsamic'], false, true),
('Beef Wellington', 'Classic beef wellington with mushroom duxelles and puff pastry', 'mains', 45.00, ARRAY['beef tenderloin', 'mushrooms', 'puff pastry'], true, true),
('Crème Brûlée', 'Vanilla custard with caramelized sugar and fresh berries', 'desserts', 10.50, ARRAY['vanilla custard', 'sugar', 'berries'], false, true),
('Gourmet Bruschetta', 'Toasted bread with heirloom tomatoes and fresh basil', 'appetizers', 11.00, ARRAY['bread', 'tomatoes', 'basil', 'olive oil'], false, true),
('Seafood Paella', 'Traditional Spanish paella with fresh seafood and saffron rice', 'mains', 32.00, ARRAY['seafood', 'saffron rice', 'peppers'], true, true),
('Tiramisu', 'Classic Italian dessert with coffee-soaked ladyfingers', 'desserts', 11.50, ARRAY['mascarpone', 'coffee', 'ladyfingers', 'cocoa'], false, true)
ON CONFLICT (id) DO NOTHING;

-- Enable Row Level Security (RLS) - Optional but recommended
ALTER TABLE dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access to dishes
CREATE POLICY "Allow public read access to dishes" ON dishes
    FOR SELECT USING (true);

-- Create policy for inserting contact messages (public can insert)
CREATE POLICY "Allow public insert to contact_messages" ON contact_messages
    FOR INSERT WITH CHECK (true);

-- Grant necessary permissions
GRANT SELECT ON dishes TO anon, authenticated;
GRANT INSERT ON contact_messages TO anon, authenticated;