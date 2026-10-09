const mongoose = require("mongoose");
const Project = require("../models/Project");

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Returns true if the value is a non-empty string that looks like a valid URL.
 * Uses the built-in URL constructor — no extra packages needed.
 */
const isValidUrl = (value) => {
    try {
        const url = new URL(value);
        return url.protocol === "http:" || url.protocol === "https:";
    } catch {
        return false;
    }
};

// ─── POST /api/projects ──────────────────────────────────────────────────────

const createProject = async (req, res) => {
    try {
        const {
            title,
            description,
            technologies,
            role,
            githubUrl,
            liveUrl,
            startDate,
            endDate,
            status
        } = req.body;

        // Required fields
        if (!title || !title.trim()) {
            return res.status(400).json({ message: "Project title is required" });
        }
        if (!description || !description.trim()) {
            return res.status(400).json({ message: "Project description is required" });
        }

        // technologies must be an array
        if (technologies !== undefined && !Array.isArray(technologies)) {
            return res.status(400).json({ message: "Technologies must be an array of strings" });
        }

        // URL validation
        if (githubUrl && !isValidUrl(githubUrl)) {
            return res.status(400).json({ message: "githubUrl must be a valid URL (http/https)" });
        }
        if (liveUrl && !isValidUrl(liveUrl)) {
            return res.status(400).json({ message: "liveUrl must be a valid URL (http/https)" });
        }

        // Date validation
        if (startDate && isNaN(Date.parse(startDate))) {
            return res.status(400).json({ message: "startDate is not a valid date" });
        }
        if (endDate && isNaN(Date.parse(endDate))) {
            return res.status(400).json({ message: "endDate is not a valid date" });
        }
        if (startDate && endDate && new Date(endDate) < new Date(startDate)) {
            return res.status(400).json({ message: "endDate cannot be earlier than startDate" });
        }

        // Status validation (mirrors schema enum)
        const allowedStatuses = ["Planned", "In Progress", "Completed"];
        if (status && !allowedStatuses.includes(status)) {
            return res.status(400).json({
                message: "Status must be one of: Planned, In Progress, Completed"
            });
        }

        const project = await Project.create({
            userId: req.user.id,
            title: title.trim(),
            description: description.trim(),
            technologies: technologies || [],
            role,
            githubUrl,
            liveUrl,
            startDate,
            endDate,
            status
        });

        return res.status(201).json({
            message: "Project created successfully",
            data: project
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/projects ───────────────────────────────────────────────────────

const getProjects = async (req, res) => {
    try {
        const projects = await Project.find({ userId: req.user.id }).sort({ createdAt: -1 });

        return res.status(200).json({
            count: projects.length,
            data: projects
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/projects/:id ───────────────────────────────────────────────────

const getProjectById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid project ID" });
        }

        const project = await Project.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!project) {
            return res.status(404).json({ message: "Project not found" });
        }

        return res.status(200).json({ data: project });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── PUT /api/projects/:id ───────────────────────────────────────────────────

const updateProject = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid project ID" });
        }

        // Ownership check — if this user doesn't own the project, return 404
        const project = await Project.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!project) {
            return res.status(404).json({ message: "Project not found" });
        }

        const {
            title,
            description,
            technologies,
            role,
            githubUrl,
            liveUrl,
            startDate,
            endDate,
            status
        } = req.body;

        // Required fields — only validate if the field is explicitly provided
        if (title !== undefined && !title.trim()) {
            return res.status(400).json({ message: "Project title cannot be empty" });
        }
        if (description !== undefined && !description.trim()) {
            return res.status(400).json({ message: "Project description cannot be empty" });
        }

        // Technologies must be an array
        if (technologies !== undefined && !Array.isArray(technologies)) {
            return res.status(400).json({ message: "Technologies must be an array of strings" });
        }

        // URL validation
        if (githubUrl !== undefined && githubUrl !== "" && !isValidUrl(githubUrl)) {
            return res.status(400).json({ message: "githubUrl must be a valid URL (http/https)" });
        }
        if (liveUrl !== undefined && liveUrl !== "" && !isValidUrl(liveUrl)) {
            return res.status(400).json({ message: "liveUrl must be a valid URL (http/https)" });
        }

        // Date validation
        if (startDate !== undefined && isNaN(Date.parse(startDate))) {
            return res.status(400).json({ message: "startDate is not a valid date" });
        }
        if (endDate !== undefined && isNaN(Date.parse(endDate))) {
            return res.status(400).json({ message: "endDate is not a valid date" });
        }

        // endDate vs startDate — resolve against existing values for partial updates
        const resolvedStart = startDate !== undefined ? new Date(startDate) : project.startDate;
        const resolvedEnd   = endDate   !== undefined ? new Date(endDate)   : project.endDate;
        if (resolvedStart && resolvedEnd && resolvedEnd < resolvedStart) {
            return res.status(400).json({ message: "endDate cannot be earlier than startDate" });
        }

        // Status validation
        const allowedStatuses = ["Planned", "In Progress", "Completed"];
        if (status !== undefined && !allowedStatuses.includes(status)) {
            return res.status(400).json({
                message: "Status must be one of: Planned, In Progress, Completed"
            });
        }

        // Build the update payload — explicitly exclude userId to prevent ownership hijack
        const updatePayload = {};
        if (title       !== undefined) updatePayload.title       = title.trim();
        if (description !== undefined) updatePayload.description = description.trim();
        if (technologies !== undefined) updatePayload.technologies = technologies;
        if (role        !== undefined) updatePayload.role        = role;
        if (githubUrl   !== undefined) updatePayload.githubUrl   = githubUrl;
        if (liveUrl     !== undefined) updatePayload.liveUrl     = liveUrl;
        if (startDate   !== undefined) updatePayload.startDate   = startDate;
        if (endDate     !== undefined) updatePayload.endDate     = endDate;
        if (status      !== undefined) updatePayload.status      = status;
        // userId is intentionally never in updatePayload

        const updatedProject = await Project.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            { new: true, runValidators: true }
        );

        return res.status(200).json({
            message: "Project updated successfully",
            data: updatedProject
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── DELETE /api/projects/:id ────────────────────────────────────────────────

const deleteProject = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid project ID" });
        }

        const project = await Project.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!project) {
            return res.status(404).json({ message: "Project not found" });
        }

        await Project.findByIdAndDelete(req.params.id);

        return res.status(200).json({ message: "Project deleted successfully" });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── Exports ─────────────────────────────────────────────────────────────────

module.exports = {
    createProject,
    getProjects,
    getProjectById,
    updateProject,
    deleteProject
};
