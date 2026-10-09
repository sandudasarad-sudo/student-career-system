const mongoose = require("mongoose");
const Skill = require("../models/Skill");

const createSkill = async (req, res) => {
    try {
        const { skillName, level } = req.body;

        if (!skillName) {
            return res.status(400).json({
                message: "Skill name is required"
            });
        }

        const skill = await Skill.create({
            userId: req.user.id,
            skillName,
            level
        });

        res.status(201).json({
            message: "Skill added successfully",
            skill
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const getSkills = async (req, res) => {
    try {
        const skills = await Skill.find({
            userId: req.user.id
        });

        res.status(200).json({
            count: skills.length,
            skills
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const getSkillById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid skill ID"
            });
        }

        const skill = await Skill.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!skill) {
            return res.status(404).json({
                message: "Skill not found"
            });
        }

        res.status(200).json({
            skill
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const updateSkill = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid skill ID"
            });
        }

        const skill = await Skill.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!skill) {
            return res.status(404).json({
                message: "Skill not found"
            });
        }

        const { skillName, level } = req.body;

        // Build explicit update payload — userId is strictly excluded
        const updatePayload = {};
        if (skillName !== undefined) updatePayload.skillName = skillName;
        if (level !== undefined) updatePayload.level = level;

        const updatedSkill = await Skill.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            {
                new: true,
                runValidators: true
            }
        );

        res.status(200).json({
            message: "Skill updated successfully",
            skill: updatedSkill
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const deleteSkill = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid skill ID"
            });
        }

        const skill = await Skill.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!skill) {
            return res.status(404).json({
                message: "Skill not found"
            });
        }

        await Skill.findByIdAndDelete(req.params.id);

        res.status(200).json({
            message: "Skill deleted successfully"
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

module.exports = {
    createSkill,
    getSkills,
    getSkillById,
    updateSkill,
    deleteSkill
};