const mongoose = require("mongoose");
const Resume        = require("../models/Resume");
const Education     = require("../models/Education");
const Skill         = require("../models/Skill");
const Project       = require("../models/Project");
const Certification = require("../models/Certification");

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Returns true if the string is a valid http/https URL.
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

/**
 * Validates that every ID in an array is:
 *   1. A valid MongoDB ObjectId.
 *   2. Owned by the authenticated user (userId === req.user.id).
 *
 * @param {string[]} ids         - Array of ID strings from the request body.
 * @param {Model}    Model       - The Mongoose model to query.
 * @param {string}   userId      - The authenticated user's ID.
 * @param {string}   label       - Human-readable label for error messages (e.g. "Education").
 *
 * @returns {{ valid: boolean, message: string, uniqueIds: string[] }}
 */
const validateOwnership = async (ids, Model, userId, label) => {
    // Must be an array
    if (!Array.isArray(ids)) {
        return { valid: false, message: `${label} IDs must be an array` };
    }

    // Validate every element is a valid ObjectId
    for (const id of ids) {
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return { valid: false, message: `Invalid ${label} ID: ${id}` };
        }
    }

    // Deduplicate
    const uniqueIds = [...new Set(ids.map((id) => id.toString()))];

    if (uniqueIds.length === 0) {
        return { valid: true, uniqueIds };
    }

    // Query only records owned by this user
    const ownedCount = await Model.countDocuments({
        _id: { $in: uniqueIds },
        userId: userId
    });

    if (ownedCount !== uniqueIds.length) {
        return {
            valid: false,
            message: `One or more ${label} IDs are invalid or do not belong to you`
        };
    }

    return { valid: true, uniqueIds };
};

/**
 * Populate all reference arrays on a resume query result.
 * Returns a fully populated Resume document.
 */
const populateResume = (query) => {
    return query
        .populate("educationIds",     "-userId -__v")
        .populate("skillIds",         "-userId -__v")
        .populate("projectIds",       "-userId -__v")
        .populate("certificationIds", "-userId -__v");
};

// ─── POST /api/resume ─────────────────────────────────────────────────────────

const createResume = async (req, res) => {
    try {
        const {
            careerObjective,
            summary,
            educationIds     = [],
            skillIds         = [],
            projectIds       = [],
            certificationIds = [],
            achievements     = [],
            languages        = [],
            resumeUrl,
            isActive
        } = req.body;

        // One resume per user — check before any validation to fail fast
        const existingResume = await Resume.findOne({ userId: req.user.id });
        if (existingResume) {
            return res.status(409).json({
                message: "Resume already exists for this user"
            });
        }

        // achievements must be array of strings
        if (!Array.isArray(achievements)) {
            return res.status(400).json({ message: "achievements must be an array of strings" });
        }
        if (!Array.isArray(languages)) {
            return res.status(400).json({ message: "languages must be an array of strings" });
        }

        // isActive must be boolean if provided
        if (isActive !== undefined && typeof isActive !== "boolean") {
            return res.status(400).json({ message: "isActive must be a boolean value" });
        }

        // resumeUrl validation
        if (resumeUrl && !isValidUrl(resumeUrl)) {
            return res.status(400).json({
                message: "resumeUrl must be a valid URL (http/https)"
            });
        }

        // Ownership validation for every reference array
        const edCheck   = await validateOwnership(educationIds,     Education,     req.user.id, "Education");
        if (!edCheck.valid)   return res.status(400).json({ message: edCheck.message });

        const skCheck   = await validateOwnership(skillIds,         Skill,         req.user.id, "Skill");
        if (!skCheck.valid)   return res.status(400).json({ message: skCheck.message });

        const prCheck   = await validateOwnership(projectIds,       Project,       req.user.id, "Project");
        if (!prCheck.valid)   return res.status(400).json({ message: prCheck.message });

        const certCheck = await validateOwnership(certificationIds, Certification, req.user.id, "Certification");
        if (!certCheck.valid) return res.status(400).json({ message: certCheck.message });

        const resume = await Resume.create({
            userId:           req.user.id,          // always from token, never from body
            careerObjective,
            summary,
            educationIds:     edCheck.uniqueIds,
            skillIds:         skCheck.uniqueIds,
            projectIds:       prCheck.uniqueIds,
            certificationIds: certCheck.uniqueIds,
            achievements,
            languages,
            resumeUrl,
            isActive
        });

        // Return populated resume
        const populated = await populateResume(Resume.findById(resume._id));

        return res.status(201).json({
            message: "Resume created successfully",
            data: populated
        });
    } catch (error) {
        // Handle duplicate key (race condition on unique userId index)
        if (error.code === 11000) {
            return res.status(409).json({ message: "Resume already exists for this user" });
        }
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/resume ──────────────────────────────────────────────────────────

const getResume = async (req, res) => {
    try {
        const resume = await populateResume(
            Resume.findOne({ userId: req.user.id })
        );

        if (!resume) {
            return res.status(404).json({ message: "Resume not found" });
        }

        return res.status(200).json({ data: resume });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/resume/my ───────────────────────────────────────────────────────

const getMyResume = async (req, res) => {
    try {
        const resume = await populateResume(
            Resume.findOne({ userId: req.user.id })
        );

        if (!resume) {
            return res.status(404).json({ message: "Resume not found" });
        }

        return res.status(200).json({ data: resume });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/resume/:id ──────────────────────────────────────────────────────

const getResumeById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid resume ID" });
        }

        const resume = await populateResume(
            Resume.findOne({ _id: req.params.id, userId: req.user.id })
        );

        if (!resume) {
            return res.status(404).json({ message: "Resume not found" });
        }

        return res.status(200).json({ data: resume });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── PUT /api/resume/:id ──────────────────────────────────────────────────────

const updateResume = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid resume ID" });
        }

        // Ownership check
        const resume = await Resume.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!resume) {
            return res.status(404).json({ message: "Resume not found" });
        }

        const {
            careerObjective,
            summary,
            educationIds,
            skillIds,
            projectIds,
            certificationIds,
            achievements,
            languages,
            resumeUrl,
            isActive
        } = req.body;

        // Validate optional arrays
        if (achievements !== undefined && !Array.isArray(achievements)) {
            return res.status(400).json({ message: "achievements must be an array of strings" });
        }
        if (languages !== undefined && !Array.isArray(languages)) {
            return res.status(400).json({ message: "languages must be an array of strings" });
        }
        if (isActive !== undefined && typeof isActive !== "boolean") {
            return res.status(400).json({ message: "isActive must be a boolean value" });
        }
        if (resumeUrl !== undefined && resumeUrl !== "" && !isValidUrl(resumeUrl)) {
            return res.status(400).json({
                message: "resumeUrl must be a valid URL (http/https)"
            });
        }

        // Build update payload — userId is intentionally NEVER included
        const updatePayload = {};

        if (careerObjective !== undefined) updatePayload.careerObjective = careerObjective;
        if (summary         !== undefined) updatePayload.summary         = summary;
        if (achievements    !== undefined) updatePayload.achievements    = achievements;
        if (languages       !== undefined) updatePayload.languages       = languages;
        if (resumeUrl       !== undefined) updatePayload.resumeUrl       = resumeUrl;
        if (isActive        !== undefined) updatePayload.isActive        = isActive;

        // Ownership validation for each reference array that was provided
        if (educationIds !== undefined) {
            const check = await validateOwnership(educationIds, Education, req.user.id, "Education");
            if (!check.valid) return res.status(400).json({ message: check.message });
            updatePayload.educationIds = check.uniqueIds;
        }
        if (skillIds !== undefined) {
            const check = await validateOwnership(skillIds, Skill, req.user.id, "Skill");
            if (!check.valid) return res.status(400).json({ message: check.message });
            updatePayload.skillIds = check.uniqueIds;
        }
        if (projectIds !== undefined) {
            const check = await validateOwnership(projectIds, Project, req.user.id, "Project");
            if (!check.valid) return res.status(400).json({ message: check.message });
            updatePayload.projectIds = check.uniqueIds;
        }
        if (certificationIds !== undefined) {
            const check = await validateOwnership(certificationIds, Certification, req.user.id, "Certification");
            if (!check.valid) return res.status(400).json({ message: check.message });
            updatePayload.certificationIds = check.uniqueIds;
        }

        const updatedResume = await Resume.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            { new: true, runValidators: true }
        );

        const populated = await populateResume(Resume.findById(updatedResume._id));

        return res.status(200).json({
            message: "Resume updated successfully",
            data: populated
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── DELETE /api/resume/:id ───────────────────────────────────────────────────

const deleteResume = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid resume ID" });
        }

        const resume = await Resume.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!resume) {
            return res.status(404).json({ message: "Resume not found" });
        }

        await Resume.findByIdAndDelete(req.params.id);

        return res.status(200).json({ message: "Resume deleted successfully" });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── Exports ──────────────────────────────────────────────────────────────────

module.exports = {
    createResume,
    getResume,
    getMyResume,
    getResumeById,
    updateResume,
    deleteResume
};
