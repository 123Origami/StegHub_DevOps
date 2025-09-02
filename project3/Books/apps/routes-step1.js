const express = require('express');
const router = express.Router();

// Test without Book model first
router.get('/books', (req, res) => {
  res.json([{ name: 'Test Book', isbn: '123', author: 'Test Author', pages: 100 }]);
});

router.post('/books', (req, res) => {
  res.json({ message: 'POST works', data: req.body });
});

router.delete('/books/:isbn', (req, res) => {
  res.json({ message: 'DELETE works', isbn: req.params.isbn });
});

console.log('Step 1 routes loaded');
module.exports = router;
