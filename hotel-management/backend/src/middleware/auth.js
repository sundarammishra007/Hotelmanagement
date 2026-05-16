const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { errorResponse } = require('../utils/response');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Access denied. No token provided.', 401);
    }
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const result = await query(
      'SELECT id, name, email, role, is_active FROM users WHERE id = $1',
      [decoded.id]
    );
    if (result.rows.length === 0) {
      return errorResponse(res, 'User not found.', 401);
    }
    const user = result.rows[0];
    if (!user.is_active) {
      return errorResponse(res, 'Account is deactivated.', 401);
    }
    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'JsonWebTokenError') {
      return errorResponse(res, 'Invalid token.', 401);
    }
    if (err.name === 'TokenExpiredError') {
      return errorResponse(res, 'Token expired.', 401);
    }
    next(err);
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Authentication required.', 401);
    }
    if (!roles.includes(req.user.role)) {
      return errorResponse(res, `Access denied. Required roles: ${roles.join(', ')}`, 403);
    }
    next();
  };
};

module.exports = { authenticate, authorize };
