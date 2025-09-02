const express = require('express');
const router = express.Router();
const Book = require('./models/book'); 

// GET all books
router.get('/books', async (req, res) => {
  try {
    const books = await Book.find();
    res.json(books);
  } catch (err) {
    console.error('Error fetching books:', err);
    res.status(500).json({ message: err.message });
  }
});

// ADD a new book
router.post('/books', async (req, res) => {
  try {
    console.log('Received book data:', req.body);
    const book = new Book(req.body);
    const savedBook = await book.save();
    res.status(201).json({
      message: 'Successfully added book',
      book: savedBook
    });
  } catch (err) {
    console.error('Error adding book:', err);
    res.status(400).json({ message: 'Error adding book', error: err.message });
  }
});

// DELETE a book by ISBN
router.delete('/books/:isbn', async (req, res) => {
  try {
    console.log('Deleting book with ISBN:', req.params.isbn);
    const result = await Book.findOneAndDelete({ isbn: req.params.isbn });
    if (!result) {
      return res.status(404).json({ message: 'Book not found' });
    }
    res.json({
      message: 'Successfully deleted the book',
      book: result
    });
  } catch (err) {
    console.error('Error deleting book:', err);
    res.status(500).json({ message: 'Error deleting book', error: err.message });
  }
});

// Test route to verify router is working
router.get('/test', (req, res) => {
  res.json({ message: 'Router is working correctly!' });
});

console.log('MongoDB routes loaded successfully');
module.exports = router;
