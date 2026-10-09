const mongoose = require("mongoose");

const resumeSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            unique: true,
            index: true
        },

        careerObjective: {
            type: String,
            trim: true
        },

        summary: {
            type: String,
            trim: true
        },

        educationIds: {
            type: [
                {
                    type: mongoose.Schema.Types.ObjectId,
                    ref: "Education"
                }
            ],
            default: []
        },

        skillIds: {
            type: [
                {
                    type: mongoose.Schema.Types.ObjectId,
                    ref: "Skill"
                }
            ],
            default: []
        },

        projectIds: {
            type: [
                {
                    type: mongoose.Schema.Types.ObjectId,
                    ref: "Project"
                }
            ],
            default: []
        },

        certificationIds: {
            type: [
                {
                    type: mongoose.Schema.Types.ObjectId,
                    ref: "Certification"
                }
            ],
            default: []
        },

        achievements: {
            type: [String],
            default: []
        },

        languages: {
            type: [String],
            default: []
        },

        resumeUrl: {
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

module.exports = mongoose.model("Resume", resumeSchema);
