const mongoose = require("mongoose");

const applicationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        jobId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Job",
            required: true,
            index: true
        },

        resumeId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Resume",
            required: true
        },

        coverLetter: {
            type: String,
            trim: true
        },

        status: {
            type: String,
            enum: {
                values: ["Applied", "Under Review", "Shortlisted", "Rejected", "Selected", "Withdrawn"],
                message: "Invalid application status"
            },
            default: "Applied"
        },

        appliedAt: {
            type: Date,
            default: Date.now
        },

        adminNotes: {
            type: String,
            trim: true
        }
    },
    {
        timestamps: true
    }
);

// Compound unique index — prevents a student from applying to the same job twice.
// Enforced at the database level, not just the controller level.
applicationSchema.index({ userId: 1, jobId: 1 }, { unique: true });

module.exports = mongoose.model("Application", applicationSchema);
