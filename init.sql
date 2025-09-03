-- Initialize the bookdb database
-- This file is executed when the MySQL container starts for the first time

USE bookdb;

-- Create the books table (GORM will handle this, but we can add some initial data)
-- The table will be created by GORM's AutoMigrate feature

-- Insert some sample data (optional)
-- INSERT INTO books (title, author, year, isbn, created_at, updated_at) VALUES
-- ('The Go Programming Language', 'Alan A. A. Donovan', 2015, '978-0134190440', NOW(), NOW()),
-- ('Clean Code', 'Robert C. Martin', 2008, '978-0132350884', NOW(), NOW()),
-- ('Design Patterns', 'Erich Gamma', 1994, '978-0201633610', NOW(), NOW());

-- Create a user for the application (optional, for better security)
-- CREATE USER 'bookapi'@'%' IDENTIFIED BY 'bookapi_password';
-- GRANT ALL PRIVILEGES ON bookdb.* TO 'bookapi'@'%';
-- FLUSH PRIVILEGES;
