const mongoose = require("mongoose");
const Application = require("../models/Application");
const Job         = require("../models/Job");
const Resume      = require("../models/Resume");

// ─── POST /api/applications (Student) ────────────────────────────────────────

const createApplication = async (req, res) => {
    try {
        const { jobId, resumeId, coverLetter } = req.body;

        // Validate jobId
        if (!jobId) {
            return res.status(400).json({ message: "jobId is required" });
        }
        if (!mongoose.Types.ObjectId.isValid(jobId)) {
            return res.status(400).json({ message: "Invalid job ID" });
        }

        // Validate resumeId if provided; otherwise auto-fetch user's resume
        let resolvedResumeId;

        if (resumeId) {
            if (!mongoose.Types.ObjectId.isValid(resumeId)) {
                return res.status(400).json({ message: "Invalid resume ID" });
            }
            // Verify the resume belongs to this user
            const ownedResume = await Resume.findOne({
                _id: resumeId,
                userId: req.user.id
            });
            if (!ownedResume) {
                return res.status(403).json({
                    message: "You can only use your own resume"
                });
            }
            resolvedResumeId = resumeId;
        } else {
            // Auto-find the user's resume (one per user)
            const userResume = await Resume.findOne({ userId: req.user.id });
            if (!userResume) {
                return res.status(400).json({
                    message: "Please create your resume before applying"
                });
            }
            resolvedResumeId = userResume._id;
        }

        // Verify the Job exists
        const job = await Job.findById(jobId);
        if (!job) {
            return res.status(404).json({ message: "Job not found" });
        }

        // Verify Job is active
        if (!job.isActive) {
            return res.status(400).json({
                message: "This job is no longer accepting applications"
            });
        }

        // Verify deadline has not passed
        if (new Date(job.applicationDeadline) < new Date()) {
            return res.status(400).json({
                message: "Application deadline has passed"
            });
        }

        // Create application — userId always from token
        const application = await Application.create({
            userId:      req.user.id,
            jobId,
            resumeId:    resolvedResumeId,
            coverLetter
        });

        const populated = await Application.findById(application._id)
            .populate("jobId",    "-createdBy -__v")
            .populate("resumeId", "-userId -__v");

        return res.status(201).json({
            message: "Application submitted successfully",
            data: populated
        });
    } catch (error) {
        // Compound unique index violation — duplicate application
        if (error.code === 11000) {
            return res.status(409).json({
                message: "You have already applied for this job"
            });
        }
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/applications ────────────────────────────────────────────────────

const getApplications = async (req, res) => {
    try {
        let filter = {};

        if (req.user.role === "admin") {
            // Admin sees all applications
            filter = {};
        } else {
            // Students see only their own
            filter = { userId: req.user.id };
        }

        const applications = await Application.find(filter)
            .populate("jobId",    "-createdBy -__v")
            .populate("resumeId", "-userId -__v")
            .sort({ appliedAt: -1 });

        return res.status(200).json({
            count: applications.length,
            data: applications
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/applications/job/:jobId (Admin only) ───────────────────────────
// IMPORTANT: This route is registered BEFORE /:id in routes to prevent
// Express treating "job" as an application ID parameter.

const getApplicationsByJob = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.jobId)) {
            return res.status(400).json({ message: "Invalid job ID" });
        }

        const job = await Job.findById(req.params.jobId);
        if (!job) {
            return res.status(404).json({ message: "Job not found" });
        }

        const applications = await Application.find({ jobId: req.params.jobId })
            .populate("userId",   "name email -_id")   // safe public fields only, no password
            .populate("jobId",    "-createdBy -__v")
            .populate("resumeId", "-userId -__v")
            .sort({ appliedAt: -1 });

        return res.status(200).json({
            count: applications.length,
            data: applications
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/applications/:id ────────────────────────────────────────────────

const getApplicationById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid application ID" });
        }

        let query = { _id: req.params.id };

        // Students can only fetch their own; admins can fetch any
        if (req.user.role !== "admin") {
            query.userId = req.user.id;
        }

        const application = await Application.findOne(query)
            .populate("jobId",    "-createdBy -__v")
            .populate("resumeId", "-userId -__v");

        if (!application) {
            return res.status(404).json({ message: "Application not found" });
        }

        return res.status(200).json({ data: application });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── PUT /api/applications/:id ────────────────────────────────────────────────

const updateApplication = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid application ID" });
        }

        // Find the application with appropriate ownership filter
        let query = { _id: req.params.id };
        if (req.user.role !== "admin") {
            query.userId = req.user.id;
        }

        const application = await Application.findOne(query);

        if (!application) {
            return res.status(404).json({ message: "Application not found" });
        }

        const { status, adminNotes, coverLetter } = req.body;

        const updatePayload = {};

        if (req.user.role === "admin") {
            // Admin can set any status and add notes
            const adminAllowedStatuses = ["Applied", "Under Review", "Shortlisted", "Rejected", "Selected", "Withdrawn"];
            if (status !== undefined) {
                if (!adminAllowedStatuses.includes(status)) {
                    return res.status(400).json({ message: "Invalid application status" });
                }
                updatePayload.status = status;
            }
            if (adminNotes !== undefined) {
                updatePayload.adminNotes = adminNotes;
            }
        } else {
            // Student can ONLY set status to "Withdrawn"
            if (status !== undefined) {
                if (status !== "Withdrawn") {
                    return res.status(403).json({
                        message: "Students may only withdraw their application"
                    });
                }
                updatePayload.status = "Withdrawn";
            }
            if (coverLetter !== undefined) {
                updatePayload.coverLetter = coverLetter;
            }
        }

        // Immutable fields — userId, jobId, resumeId, appliedAt are never in updatePayload

        if (Object.keys(updatePayload).length === 0) {
            return res.status(400).json({ message: "No valid fields provided for update" });
        }

        const updatedApplication = await Application.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            { new: true, runValidators: true }
        )
            .populate("jobId",    "-createdBy -__v")
            .populate("resumeId", "-userId -__v");

        return res.status(200).json({
            message: "Application updated successfully",
            data: updatedApplication
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── DELETE /api/applications/:id ────────────────────────────────────────────

const deleteApplication = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid application ID" });
        }

        let query = { _id: req.params.id };

        // Students can only delete their own; admins can delete any
        if (req.user.role !== "admin") {
            query.userId = req.user.id;
        }

        const application = await Application.findOne(query);

        if (!application) {
            return res.status(404).json({ message: "Application not found" });
        }

        await Application.findByIdAndDelete(req.params.id);

        return res.status(200).json({ message: "Application deleted successfully" });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── Exports ──────────────────────────────────────────────────────────────────

module.exports = {
    createApplication,
    getApplications,
    getApplicationsByJob,
    getApplicationById,
    updateApplication,
    deleteApplication
};
