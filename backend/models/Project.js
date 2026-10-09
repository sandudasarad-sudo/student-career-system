const mongoose = require("mongoose");

const projectSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        title: {
            type: String,
            required: [true, "Project title is required"],
            trim: true
        },

        description: {
            type: String,
            required: [true, "Project description is required"],
            trim: true
        },

        technologies: {
            type: [String],
            default: []
        },

        role: {
            type: String,
            trim: true
        },

        githubUrl: {
            type: String,
            trim: true
        },

        liveUrl: {
            type: String,
            trim: true
        },

        startDate: {
            type: Date
        },

        endDate: {
            type: Date
        },

        status: {
            type: String,
            enum: {
                values: ["Planned", "In Progress", "Completed"],
                message: "Status must be one of: Planned, In Progress, Completed"
            },
            default: "In Progress"
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Project", projectSchema);
