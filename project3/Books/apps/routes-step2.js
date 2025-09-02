const express = require('express');
const router = express.Router();

// Test adding the Book model
console.log('Attempting to require Book model...');
try {
  const Book = require('../models/book');
  console.log('✅ Book model loaded successfully');
  
  router.get('/books', async (req, res) => {
    try {
      const books = await Book.find();
      res.json(books);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  });
  
} catch (error) {
  console.error('❌ Failed to load Book model:', error.message);
  // Fallback route without database
  router.get('/books', (req, res) => {
    res.json([{ name: 'Fallback Book', isbn: '123' }]);
  });
}

console.log('Step 2 routes loaded');
module.exports = router;
