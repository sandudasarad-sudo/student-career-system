const mongoose = require("mongoose");

const educationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        degree: {
            type: String,
            required: true,
            trim: true
        },

        institution: {
            type: String,
            required: true,
            trim: true
        },

        branch: {
            type: String,
            trim: true
        },

        startYear: {
            type: Number,
            min: [1900, "Start year must be after 1900"],
            max: [2100, "Start year seems too far in the future"]
        },

        endYear: {
            type: Number,
            min: [1900, "End year must be after 1900"],
            max: [2100, "End year seems too far in the future"]
        },

        cgpa: {
            type: Number,
            min: [0, "CGPA cannot be less than 0"],
            max: [10, "CGPA cannot exceed 10"]
        },

        educationLevel: {
            type: String,
            enum: ["10th", "12th", "Diploma", "Bachelor's", "Master's", "PhD", "Other"],
            trim: true
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Education", educationSchema);
