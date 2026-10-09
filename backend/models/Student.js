const mongoose = require("mongoose");

const studentSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            unique: true
        },

        name: {
            type: String,
            required: true,
            trim: true
        },

        email: {
            type: String,
            required: true,
            lowercase: true,
            trim: true
        },

        phone: {
            type: String,
            trim: true
        },

        dateOfBirth: {
            type: Date
        },

        gender: {
            type: String,
            enum: ["Male", "Female", "Other"]
        },

        college: {
            type: String,
            trim: true
        },

        branch: {
            type: String,
            trim: true
        },

        year: {
            type: Number
        },

        cgpa: {
            type: Number
        },

        skills: {
            type: [String],
            default: []
        },

        address: {
            type: String,
            trim: true
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Student", studentSchema);