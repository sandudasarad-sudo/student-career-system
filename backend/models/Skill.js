const mongoose = require("mongoose");

const skillSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        skillName: {
            type: String,
            required: true,
            trim: true
        },

        level: {
            type: String,
            enum: ["Beginner", "Intermediate", "Advanced", "Expert"],
            default: "Beginner"
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Skill", skillSchema);