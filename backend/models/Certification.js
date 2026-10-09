const mongoose = require("mongoose");

const certificationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        title: {
            type: String,
            required: [true, "Certification title is required"],
            trim: true
        },

        issuer: {
            type: String,
            required: [true, "Issuer is required"],
            trim: true
        },

        issueDate: {
            type: Date,
            required: [true, "Issue date is required"]
        },

        expiryDate: {
            type: Date
        },

        credentialId: {
            type: String,
            trim: true
        },

        credentialUrl: {
            type: String,
            trim: true
        },

        description: {
            type: String,
            trim: true
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Certification", certificationSchema);
