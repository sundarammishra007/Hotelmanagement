const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Express-validator errors
  if (err.type === 'validation' && err.errors) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: err.errors,
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({ success: false, message: 'Token expired' });
  }

  // PostgreSQL errors
  if (err.code) {
    switch (err.code) {
      case '23505': // unique violation
        return res.status(409).json({
          success: false,
          message: 'Record already exists',
          detail: err.detail || 'Duplicate entry',
        });
      case '23502': // not null violation
        return res.status(400).json({
          success: false,
          message: `Missing required field: ${err.column}`,
        });
      case '23503': // foreign key violation
        return res.status(400).json({
          success: false,
          message: 'Referenced record does not exist',
        });
      case '22P02': // invalid text representation (bad UUID etc)
        return res.status(400).json({
          success: false,
          message: 'Invalid ID format',
        });
      default:
        break;
    }
  }

  // Multer errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ success: false, message: 'File too large. Max 5MB.' });
  }

  const statusCode = err.statusCode || err.status || 500;
  res.status(statusCode).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = errorHandler;
