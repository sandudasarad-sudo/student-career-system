const express = require("express");
const router = express.Router();

const {
    createResume,
    getResume,
    getMyResume,
    getResumeById,
    updateResume,
    deleteResume
} = require("../controllers/resumeController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/",    authMiddleware, createResume);

router.get("/",    authMiddleware, getResume);

// IMPORTANT: /my must be defined BEFORE /:id
// Otherwise Express will treat "my" as an ID parameter.
router.get("/my",  authMiddleware, getMyResume);

router.get("/:id", authMiddleware, getResumeById);

router.put("/:id", authMiddleware, updateResume);

router.delete("/:id", authMiddleware, deleteResume);

module.exports = router;
