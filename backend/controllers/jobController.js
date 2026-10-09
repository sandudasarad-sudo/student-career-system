const mongoose = require("mongoose");
const Job         = require("../models/Job");
const Application = require("../models/Application");

// ─── Helpers ─────────────────────────────────────────────────────────────────

const isValidUrl = (value) => {
    try {
        const url = new URL(value);
        return url.protocol === "http:" || url.protocol === "https:";
    } catch {
        return false;
    }
};

const VALID_JOB_TYPES = ["Full-time", "Part-time", "Internship", "Contract", "Remote"];

// ─── POST /api/jobs (Admin only) ──────────────────────────────────────────────

const createJob = async (req, res) => {
    try {
        const {
            title,
            company,
            location,
            jobType,
            description,
            requirements = [],
            skills = [],
            salaryMin,
            salaryMax,
            applicationDeadline,
            externalApplyUrl,
            isActive
        } = req.body;

        // Required fields
        if (!title || !title.trim()) {
            return res.status(400).json({ message: "Job title is required" });
        }
        if (!company || !company.trim()) {
            return res.status(400).json({ message: "Company name is required" });
        }
        if (!description || !description.trim()) {
            return res.status(400).json({ message: "Job description is required" });
        }
        if (!jobType) {
            return res.status(400).json({ message: "Job type is required" });
        }
        if (!VALID_JOB_TYPES.includes(jobType)) {
            return res.status(400).json({
                message: `jobType must be one of: ${VALID_JOB_TYPES.join(", ")}`
            });
        }
        if (!applicationDeadline) {
            return res.status(400).json({ message: "Application deadline is required" });
        }
        if (isNaN(Date.parse(applicationDeadline))) {
            return res.status(400).json({ message: "applicationDeadline is not a valid date" });
        }
        if (new Date(applicationDeadline) <= new Date()) {
            return res.status(400).json({ message: "Application deadline must be a future date" });
        }

        // Salary validation
        if (salaryMin !== undefined && salaryMin < 0) {
            return res.status(400).json({ message: "salaryMin cannot be negative" });
        }
        if (salaryMax !== undefined && salaryMax < 0) {
            return res.status(400).json({ message: "salaryMax cannot be negative" });
        }
        if (salaryMin !== undefined && salaryMax !== undefined && salaryMax < salaryMin) {
            return res.status(400).json({ message: "salaryMax must be greater than or equal to salaryMin" });
        }

        // URL validation
        if (externalApplyUrl && !isValidUrl(externalApplyUrl)) {
            return res.status(400).json({ message: "externalApplyUrl must be a valid URL (http/https)" });
        }

        // Arrays
        if (!Array.isArray(requirements)) {
            return res.status(400).json({ message: "requirements must be an array" });
        }
        if (!Array.isArray(skills)) {
            return res.status(400).json({ message: "skills must be an array" });
        }

        const job = await Job.create({
            createdBy: req.user.id,   // always from token
            title: title.trim(),
            company: company.trim(),
            location,
            jobType,
            description: description.trim(),
            requirements,
            skills,
            salaryMin,
            salaryMax,
            applicationDeadline,
            externalApplyUrl,
            isActive: isActive !== undefined ? isActive : true
        });

        return res.status(201).json({
            message: "Job created successfully",
            data: job
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/jobs (All authenticated users) ─────────────────────────────────

const getJobs = async (req, res) => {
    try {
        let filter = {};

        if (req.user.role === "admin") {
            // Admins see everything
            filter = {};
        } else {
            // Students see only active jobs with non-expired deadlines
            filter = {
                isActive: true,
                applicationDeadline: { $gte: new Date() }
            };
        }

        const jobs = await Job.find(filter).sort({ applicationDeadline: 1 });

        return res.status(200).json({
            count: jobs.length,
            data: jobs
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/jobs/:id (All authenticated users) ─────────────────────────────

const getJobById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid job ID" });
        }

        const job = await Job.findById(req.params.id);

        if (!job) {
            return res.status(404).json({ message: "Job not found" });
        }

        // Students cannot see inactive or expired jobs
        if (req.user.role !== "admin") {
            if (!job.isActive || new Date(job.applicationDeadline) < new Date()) {
                return res.status(404).json({ message: "Job not found" });
            }
        }

        return res.status(200).json({ data: job });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── PUT /api/jobs/:id (Admin only) ──────────────────────────────────────────

const updateJob = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid job ID" });
        }

        const job = await Job.findById(req.params.id);

        if (!job) {
            return res.status(404).json({ message: "Job not found" });
        }

        const {
            title,
            company,
            location,
            jobType,
            description,
            requirements,
            skills,
            salaryMin,
            salaryMax,
            applicationDeadline,
            externalApplyUrl,
            isActive
        } = req.body;

        // Validate provided fields only (partial update)
        if (title !== undefined && !title.trim()) {
            return res.status(400).json({ message: "Job title cannot be empty" });
        }
        if (company !== undefined && !company.trim()) {
            return res.status(400).json({ message: "Company name cannot be empty" });
        }
        if (description !== undefined && !description.trim()) {
            return res.status(400).json({ message: "Job description cannot be empty" });
        }
        if (jobType !== undefined && !VALID_JOB_TYPES.includes(jobType)) {
            return res.status(400).json({
                message: `jobType must be one of: ${VALID_JOB_TYPES.join(", ")}`
            });
        }
        if (applicationDeadline !== undefined) {
            if (isNaN(Date.parse(applicationDeadline))) {
                return res.status(400).json({ message: "applicationDeadline is not a valid date" });
            }
            if (new Date(applicationDeadline) <= new Date()) {
                return res.status(400).json({ message: "Application deadline must be a future date" });
            }
        }

        // Salary range — resolve against existing values for partial updates
        const resolvedMin = salaryMin !== undefined ? salaryMin : job.salaryMin;
        const resolvedMax = salaryMax !== undefined ? salaryMax : job.salaryMax;
        if (salaryMin !== undefined && salaryMin < 0) {
            return res.status(400).json({ message: "salaryMin cannot be negative" });
        }
        if (salaryMax !== undefined && salaryMax < 0) {
            return res.status(400).json({ message: "salaryMax cannot be negative" });
        }
        if (resolvedMin !== undefined && resolvedMax !== undefined && resolvedMax < resolvedMin) {
            return res.status(400).json({ message: "salaryMax must be greater than or equal to salaryMin" });
        }

        if (externalApplyUrl !== undefined && externalApplyUrl !== "" && !isValidUrl(externalApplyUrl)) {
            return res.status(400).json({ message: "externalApplyUrl must be a valid URL (http/https)" });
        }
        if (requirements !== undefined && !Array.isArray(requirements)) {
            return res.status(400).json({ message: "requirements must be an array" });
        }
        if (skills !== undefined && !Array.isArray(skills)) {
            return res.status(400).json({ message: "skills must be an array" });
        }

        // Build update payload — createdBy is intentionally excluded
        const updatePayload = {};
        if (title               !== undefined) updatePayload.title               = title.trim();
        if (company             !== undefined) updatePayload.company             = company.trim();
        if (location            !== undefined) updatePayload.location            = location;
        if (jobType             !== undefined) updatePayload.jobType             = jobType;
        if (description         !== undefined) updatePayload.description         = description.trim();
        if (requirements        !== undefined) updatePayload.requirements        = requirements;
        if (skills              !== undefined) updatePayload.skills              = skills;
        if (salaryMin           !== undefined) updatePayload.salaryMin           = salaryMin;
        if (salaryMax           !== undefined) updatePayload.salaryMax           = salaryMax;
        if (applicationDeadline !== undefined) updatePayload.applicationDeadline = applicationDeadline;
        if (externalApplyUrl    !== undefined) updatePayload.externalApplyUrl    = externalApplyUrl;
        if (isActive            !== undefined) updatePayload.isActive            = isActive;

        const updatedJob = await Job.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            { new: true, runValidators: true }
        );

        return res.status(200).json({
            message: "Job updated successfully",
            data: updatedJob
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── DELETE /api/jobs/:id (Admin only) ───────────────────────────────────────

const deleteJob = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid job ID" });
        }

        const job = await Job.findById(req.params.id);

        if (!job) {
            return res.status(404).json({ message: "Job not found" });
        }

        // Prevent deletion if applications exist — avoids orphaned references
        const applicationCount = await Application.countDocuments({ jobId: req.params.id });
        if (applicationCount > 0) {
            return res.status(409).json({
                message: "Cannot delete a job with existing applications. Deactivate it instead."
            });
        }

        await Job.findByIdAndDelete(req.params.id);

        return res.status(200).json({ message: "Job deleted successfully" });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── Exports ──────────────────────────────────────────────────────────────────

module.exports = {
    createJob,
    getJobs,
    getJobById,
    updateJob,
    deleteJob
};
