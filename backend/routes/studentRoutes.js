const express = require("express");
const router = express.Router();

const {
    createStudent,
    getStudents,
    getStudentById,
    updateStudent,
    deleteStudent
} = require("../controllers/studentController");

const authMiddleware = require("../middleware/authMiddleware");
const requireRole = require("../middleware/roleMiddleware");

router.post("/", authMiddleware, createStudent);

// Restrict entire student directory listing to admins to protect student privacy
router.get("/", authMiddleware, requireRole("admin"), getStudents);

router.get("/:id", authMiddleware, getStudentById);

router.put("/:id", authMiddleware, updateStudent);

router.delete("/:id", authMiddleware, deleteStudent);

module.exports = router;
