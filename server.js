// ========================================================
// ROUTESYNC: PUBLIC TRANSPORT OPTIMISATION SYSTEM
// MAIN EXPRESS SERVER ENTRY POINT
// ========================================================
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { errorHandler } = require('./middleware/errorMiddleware');

// Initialize Environment Variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS with dynamic settings
app.use(cors({
  origin: '*', // Allow connections from Vite Dev Server
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Express middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Server basic status / Health check
app.get('/api/health', (req, res) => {
  const db = require('./config/db');
  res.status(200).json({
    status: 'online',
    timestamp: new Date(),
    databaseMode: db.isMock() ? 'Simulated Mock Database' : 'MySQL Live Connection',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Register API Routes
app.use('/api/passengers', require('./routes/passengerRoutes'));
app.use('/api/drivers', require('./routes/driverRoutes'));
app.use('/api/vehicles', require('./routes/vehicleRoutes'));
app.use('/api/routes', require('./routes/routeRoutes'));
app.use('/api/schedules', require('./routes/scheduleRoutes'));
app.use('/api/stops', require('./routes/stopRoutes'));
app.use('/api/tickets', require('./routes/ticketRoutes'));
app.use('/api/reports', require('./routes/reportRoutes'));

// 404 Route handler
app.use((req, res, next) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found.` });
});

// Centralized Error Handling Middleware
app.use(errorHandler);

// Start the Express Server
app.listen(PORT, () => {
  console.log('====================================================');
  console.log(`🌐 ROUTESYNC EXPRESS SERVER IS RUNNING ON PORT ${PORT}`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
  console.log('====================================================');
});
