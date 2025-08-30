import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load environment variables
dotenv.config();

// ES modules __dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Import routes
import portfolioRoutes from './routes/portfolio.js';
import contactRoutes from './routes/contact.js';
import chatbotRoutes from './routes/chatbot.js';

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({
  origin: [process.env.FRONTEND_URL || 'http://localhost:3000', 'http://localhost:3001', 'http://localhost:3002'],
  credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files in production
if (process.env.NODE_ENV === 'production') {
  // Serve static files from the dist directory
  app.use(express.static(path.join(__dirname, '../dist')));
}

// Routes
app.use('/api/portfolio', portfolioRoutes);
app.use('/api/contact', contactRoutes);
app.use('/api/chatbot', chatbotRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    message: 'Food Portfolio API is running!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err : {}
  });
});

// Handle React routing in production
if (process.env.NODE_ENV === 'production') {
  app.get('*', (req, res) => {
    // Don't serve index.html for API routes
    if (req.path.startsWith('/api/')) {
      return res.status(404).json({
        message: 'API endpoint not found',
        availableEndpoints: [
          'GET /api/health',
          'GET /api/portfolio',
          'POST /api/portfolio',
          'PUT /api/portfolio/:id',
          'DELETE /api/portfolio/:id',
          'POST /api/contact',
          'POST /api/chatbot/chat',
          'POST /api/chatbot/recommend',
          'GET /api/chatbot/status'
        ]
      });
    }
    // Serve React app for all other routes
    res.sendFile(path.join(__dirname, '../dist/index.html'));
  });
} else {
  // 404 handler for development
  app.use('*', (req, res) => {
    res.status(404).json({
      message: 'API endpoint not found',
      availableEndpoints: [
        'GET /api/health',
        'GET /api/portfolio',
        'POST /api/portfolio',
        'PUT /api/portfolio/:id',
        'DELETE /api/portfolio/:id',
        'POST /api/contact',
        'POST /api/chatbot/chat',
        'POST /api/chatbot/recommend',
        'GET /api/chatbot/status'
      ]
    });
  });
}

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Food Portfolio API Server running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
  console.log(`💾 Supabase URL: ${process.env.SUPABASE_URL ? 'Connected' : 'Not configured'}`);
});

export default app;