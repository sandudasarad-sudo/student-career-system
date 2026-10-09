const express = require("express");
const router = express.Router();

const {
    createEducation,
    getEducations,
    getEducationById,
    updateEducation,
    deleteEducation
} = require("../controllers/educationController");

const protect = require("../middleware/authMiddleware");

router.post("/", protect, createEducation);

router.get("/", protect, getEducations);

router.get("/:id", protect, getEducationById);

router.put("/:id", protect, updateEducation);

router.delete("/:id", protect, deleteEducation);

module.exports = router;
