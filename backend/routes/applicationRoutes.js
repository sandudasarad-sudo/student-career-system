const express = require("express");
const router = express.Router();

const {
    createApplication,
    getApplications,
    getApplicationsByJob,
    getApplicationById,
    updateApplication,
    deleteApplication
} = require("../controllers/applicationController");

const protect     = require("../middleware/authMiddleware");
const requireRole = require("../middleware/roleMiddleware");

// Student submits an application
router.post("/", protect, createApplication);

// List applications — students see their own, admins see all (handled in controller)
router.get("/", protect, getApplications);

// IMPORTANT: /job/:jobId must be registered BEFORE /:id
// so Express does not treat "job" as an application ID parameter.
router.get("/job/:jobId", protect, requireRole("admin"), getApplicationsByJob);

// Get single application by ID
router.get("/:id", protect, getApplicationById);

// Update application — role-based logic handled in controller
router.put("/:id", protect, updateApplication);

// Delete application
router.delete("/:id", protect, deleteApplication);

module.exports = router;
