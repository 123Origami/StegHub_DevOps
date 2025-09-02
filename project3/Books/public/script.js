angular.module('myApp', [])
  .controller('myCtrl', function($scope, $http) {
    
    // Initialize scope variables
    $scope.books = [];
    $scope.Name = '';
    $scope.Isbn = '';
    $scope.Author = '';
    $scope.Pages = '';
    
    // Function to fetch all books from the server
    function fetchBooks() {
      $http.get('/api/books')  // Fixed: changed from '/book' to '/api/books'
        .then(response => {
          $scope.books = response.data;
          console.log('Books loaded:', $scope.books);
        })
        .catch(error => {
          console.error('Error fetching books:', error);
          alert('Error fetching books. Please check the console.');
        });
    }
    
    // Load books when controller initializes
    fetchBooks();
    
    // Function to delete a book
    $scope.del_book = function(book) {
      if (confirm(`Are you sure you want to delete "${book.name}"?`)) {
        $http.delete(`/api/books/${book.isbn}`)  // Fixed: changed from '/book/' to '/api/books/'
          .then(() => {
            console.log('Book deleted successfully');
            fetchBooks(); // Refresh the list
          })
          .catch(error => {
            console.error('Error deleting book:', error);
            alert('Error deleting book. Please check the console.');
          });
      }
    };
    
    // Function to add a new book
    $scope.add_book = function() {
      // Validate form data
      if (!$scope.Name || !$scope.Isbn || !$scope.Author || !$scope.Pages) {
        alert('Please fill in all fields');
        return;
      }
      
      if ($scope.Pages <= 0) {
        alert('Pages must be a positive number');
        return;
      }
      
      const newBook = {
        name: $scope.Name,
        isbn: $scope.Isbn,
        author: $scope.Author,
        pages: parseInt($scope.Pages) // Fixed: added missing pages field and converted to number
      };
      
      console.log('Adding book:', newBook);
      
      $http.post('/api/books', newBook)  // Fixed: changed from '/book' to '/api/books'
        .then(response => {
          console.log('Book added successfully:', response.data);
          fetchBooks(); // Refresh the list
          // Clear form fields
          $scope.Name = '';
          $scope.Isbn = '';
          $scope.Author = '';
          $scope.Pages = '';
        })
        .catch(error => {
          console.error('Error adding book:', error);
          alert('Error adding book: ' + (error.data?.error || error.statusText));
        });
    };
    
    // Optional: Test function to check API connectivity
    $scope.test_api = function() {
      $http.get('/api/status')
        .then(response => {
          alert('API Test Success: ' + response.data.message);
          console.log('API Status:', response.data);
        })
        .catch(error => {
          alert('API Test Failed - Check console for details');
          console.error('API Test Error:', error);
        });
    };
    
  });
