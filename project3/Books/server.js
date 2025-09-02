const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const app = express();
const PORT = process.env.PORT || 3300;

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true }));

// Basic test route
app.get('/api/status', (req, res) => {
  res.json({
    message: 'Server is running!',
    timestamp: new Date().toISOString(),
    mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected'
  });
});

// Use an async function to start the server
async function startServer() {
  try {
    console.log('Starting server...');
    console.log('Connecting to MongoDB...');
    
    // Await the MongoDB connection to ensure it's ready
    await mongoose.connect('mongodb://localhost:27017/bookstore');
    console.log('✅ Connected to MongoDB successfully');

    // Load and mount API routes
    const routesPath = './apps/routes';
    if (fs.existsSync(path.join(__dirname, routesPath + '.js'))) {
      console.log(`Loading routes from ${routesPath}...`);
      const routes = require(routesPath);
      app.use('/api', routes);
      console.log('✅ Routes mounted successfully on /api');
    } else {
      throw new Error(`Routes file not found at ${routesPath}`);
    }

    // Health check endpoint
    app.get('/health', (req, res) => {
      res.json({
        status: 'OK',
        uptime: process.uptime(),
        mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
        timestamp: new Date().toISOString()
      });
    });

    // Catch-all route for Angular SPA
    app.get('*', (req, res) => {
      const indexPath = path.join(__dirname, 'public', 'index.html');
      if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
      } else {
        res.status(404).json({
          message: 'Angular app would load here',
          note: 'Place your Angular build files in the public/ directory'
        });
      }
    });

    // Start server after everything is ready
    app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
      console.log('📍 Available API endpoints:');
      console.log('   - GET    /api/status   (Server status)');
      console.log('   - GET    /api/books    (Get all books)');
      console.log('   - POST   /api/books    (Add new book)');
      console.log('   - DELETE /api/books/:isbn (Delete book by ISBN)');
      console.log('   - GET    /health       (Health check)');
      console.log('');
      console.log('🔗 Test URLs:');
      console.log(`   http://localhost:${PORT}/api/status`);
      console.log(`   http://localhost:${PORT}/api/books`);
    });

  } catch (err) {
    console.error('❌ FAILED to start server:', err.message);
    process.exit(1); // Exit with a failure code
  }
}

// Call the async function to run the server
startServer();
