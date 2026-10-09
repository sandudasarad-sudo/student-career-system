const express = require("express");
const router = express.Router();

const {
    createSkill,
    getSkills,
    getSkillById,
    updateSkill,
    deleteSkill
} = require("../controllers/skillController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/", authMiddleware, createSkill);

router.get("/", authMiddleware, getSkills);

router.get("/:id", authMiddleware, getSkillById);

router.put("/:id", authMiddleware, updateSkill);

router.delete("/:id", authMiddleware, deleteSkill);

module.exports = router;