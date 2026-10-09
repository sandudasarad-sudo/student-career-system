const mongoose = require("mongoose");

const jobSchema = new mongoose.Schema(
    {
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        title: {
            type: String,
            required: [true, "Job title is required"],
            trim: true
        },

        company: {
            type: String,
            required: [true, "Company name is required"],
            trim: true
        },

        location: {
            type: String,
            trim: true
        },

        jobType: {
            type: String,
            enum: {
                values: ["Full-time", "Part-time", "Internship", "Contract", "Remote"],
                message: "jobType must be one of: Full-time, Part-time, Internship, Contract, Remote"
            },
            required: [true, "Job type is required"]
        },

        description: {
            type: String,
            required: [true, "Job description is required"],
            trim: true
        },

        requirements: {
            type: [String],
            default: []
        },

        skills: {
            type: [String],
            default: []
        },

        salaryMin: {
            type: Number,
            min: [0, "Minimum salary cannot be negative"]
        },

        salaryMax: {
            type: Number,
            min: [0, "Maximum salary cannot be negative"]
        },

        applicationDeadline: {
            type: Date,
            required: [true, "Application deadline is required"]
        },

        externalApplyUrl: {
            type: String,
            trim: true
        },

        isActive: {
            type: Boolean,
            default: true
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Job", jobSchema);
