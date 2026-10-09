const express = require("express");
const router = express.Router();

const {
    getDashboard,
    getUsers,
    getUserById,
    getStudents,
    getStudentDetails,
    getApplicationAnalytics,
    getJobAnalytics
} = require("../controllers/adminController");

const protect     = require("../middleware/authMiddleware");
const requireRole = require("../middleware/roleMiddleware");

// All admin routes strictly require JWT and "admin" role
router.use(protect, requireRole("admin"));

// Dashboard overview
router.get("/dashboard", getDashboard);

// User management
router.get("/users", getUsers);
router.get("/users/:id", getUserById);

// Student profiles and consolidated student details
router.get("/students", getStudents);
router.get("/students/:userId", getStudentDetails);

// Analytics
router.get("/analytics/applications", getApplicationAnalytics);
router.get("/analytics/jobs", getJobAnalytics);

module.exports = router;
