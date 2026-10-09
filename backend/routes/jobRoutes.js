const express = require("express");
const router = express.Router();

const {
    createJob,
    getJobs,
    getJobById,
    updateJob,
    deleteJob
} = require("../controllers/jobController");

const protect      = require("../middleware/authMiddleware");
const requireRole  = require("../middleware/roleMiddleware");

// Students and admins can view jobs
router.get("/",    protect, getJobs);
router.get("/:id", protect, getJobById);

// Admin only — job management
router.post(  "/",    protect, requireRole("admin"), createJob);
router.put(   "/:id", protect, requireRole("admin"), updateJob);
router.delete("/:id", protect, requireRole("admin"), deleteJob);

module.exports = router;
