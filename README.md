# Food Portfolio Website with Supabase Backend

A modern, responsive food portfolio website built with React (frontend) and Node.js/Express (backend) with Supabase as the database.

## 🚀 Features

### Frontend
- Modern React with Vite
- Responsive design for all devices
- Interactive portfolio gallery with filtering
- Contact form with validation
- Smooth animations and transitions
- Professional food portfolio layout

### Backend
- Node.js/Express REST API
- Supabase PostgreSQL database
- CRUD operations for dishes
- Contact form handling
- Admin endpoints for management
- Error handling and validation

## 📋 Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Supabase account (free tier available)

## 🛠️ Setup Instructions

### 1. Supabase Setup

1. **Create a Supabase project:**
   - Go to [https://supabase.com](https://supabase.com)
   - Sign up/log in and create a new project
   - Wait for the project to be fully initialized

2. **Get your project credentials:**
   - Go to Settings > API
   - Copy your Project URL
   - Copy your `anon/public` key
   - Copy your `service_role` key (keep this secret!)

3. **Set up the database:**
   - Go to the SQL Editor in your Supabase dashboard
   - Copy the contents of `server/database/schema.sql`
   - Paste and run the SQL script
   - This will create the necessary tables and sample data

### 2. Environment Configuration

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Update your `.env` file with your Supabase credentials:**
   ```env
   # Supabase Configuration
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   
   # Server Configuration
   PORT=5000
   NODE_ENV=development
   
   # Frontend URL (for CORS)
   FRONTEND_URL=http://localhost:3000
   ```

### 3. Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

### 4. Running the Application

**Option 1: Run frontend and backend separately**

Terminal 1 (Frontend):
```bash
npm run dev
```

Terminal 2 (Backend):
```bash
npm run server:dev
```

**Option 2: Run both simultaneously**
```bash
npm run dev:full
```

The frontend will be available at `http://localhost:3000` and the backend API at `http://localhost:5000`

## 📊 API Endpoints

### Portfolio/Dishes
- `GET /api/portfolio` - Get all dishes
- `GET /api/portfolio?category=mains` - Get dishes by category
- `GET /api/portfolio?featured=true` - Get featured dishes
- `GET /api/portfolio?search=salmon` - Search dishes
- `GET /api/portfolio/:id` - Get single dish
- `GET /api/portfolio/categories` - Get all categories
- `GET /api/portfolio/stats` - Get portfolio statistics

### Contact
- `POST /api/contact` - Submit contact form
- `GET /api/contact` - Get all messages (admin)
- `GET /api/contact/:id` - Get single message (admin)
- `PUT /api/contact/:id/status` - Update message status (admin)
- `GET /api/contact/stats` - Get contact statistics (admin)

### System
- `GET /api/health` - Health check

## 🗄️ Database Schema

### Dishes Table
- `id` (UUID, Primary Key)
- `title` (VARCHAR, Required)
- `description` (TEXT)
- `category` (ENUM: appetizers, mains, desserts, drinks, specials)
- `image_url` (TEXT)
- `price` (DECIMAL)
- `ingredients` (TEXT[])
- `is_featured` (BOOLEAN)
- `is_available` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Contact Messages Table
- `id` (UUID, Primary Key)
- `name` (VARCHAR, Required)
- `email` (VARCHAR, Required)
- `phone` (VARCHAR)
- `event_type` (VARCHAR)
- `guests` (INTEGER)
- `preferred_date` (DATE)
- `message` (TEXT, Required)
- `status` (ENUM: new, in_progress, completed, archived)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

## 🔧 Project Structure

```
food-portfolio/
├── src/                    # Frontend React code
│   ├── components/         # React components
│   ├── styles/            # CSS files
│   └── main.jsx           # React entry point
├── server/                # Backend Node.js code
│   ├── config/            # Configuration files
│   ├── controllers/       # Route controllers
│   ├── models/           # Database models
│   ├── routes/           # API routes
│   ├── database/         # SQL schema files
│   └── index.js          # Server entry point
├── public/               # Static files
├── .env                  # Environment variables
├── .env.example         # Environment template
├── package.json         # Dependencies and scripts
└── vite.config.js       # Vite configuration
```

## 🚀 Deployment

### Frontend (Netlify/Vercel)
1. Build the frontend: `npm run build`
2. Deploy the `dist` folder to your hosting provider
3. Update the backend URL in production

### Backend (Railway/Heroku/DigitalOcean)
1. Deploy the entire project
2. Set environment variables on your hosting platform
3. Update CORS settings for production frontend URL

## 🔐 Security Notes

1. **Never commit your `.env` file** - it's already in `.gitignore`
2. **Keep your `service_role` key secret** - only use it server-side
3. **Set up proper Row Level Security (RLS)** in Supabase for production
4. **Add authentication middleware** for admin routes in production
5. **Validate and sanitize all inputs** before database operations

## 🛡️ Row Level Security (RLS)

The database schema includes basic RLS policies:
- Public read access to dishes
- Public insert access to contact messages
- Admin operations require proper authentication (implement as needed)

## 📝 Example Usage

### Fetching dishes in frontend:
```javascript
const response = await fetch('http://localhost:5000/api/portfolio');
const data = await response.json();
console.log(data.data); // Array of dishes
```

### Submitting contact form:
```javascript
const response = await fetch('http://localhost:5000/api/contact', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'John Doe',
    email: 'john@example.com',
    message: 'I would like to book a catering service.'
  })
});
```

## 🔍 Troubleshooting

1. **Database connection issues:**
   - Verify your Supabase credentials in `.env`
   - Check if your IP is allowed in Supabase (should be open by default)
   - Ensure the database schema was created successfully

2. **CORS errors:**
   - Verify `FRONTEND_URL` in your `.env` file
   - Check that both frontend and backend are running on correct ports

3. **Module not found errors:**
   - Run `npm install` to ensure all dependencies are installed
   - Clear node_modules and reinstall if necessary

## 📄 License

This project is licensed under the ISC License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For questions or issues, please create an issue in the repository or contact the development team.