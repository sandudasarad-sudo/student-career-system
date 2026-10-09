const mongoose = require("mongoose");
const Education = require("../models/Education");

// POST /api/education — Create a new education record
const createEducation = async (req, res) => {
    try {
        const { degree, institution, branch, startYear, endYear, cgpa, educationLevel } = req.body;

        // Required field validation
        if (!degree || !institution) {
            return res.status(400).json({
                message: "Degree and institution are required"
            });
        }

        // Year validation
        if (startYear && endYear && endYear < startYear) {
            return res.status(400).json({
                message: "End year cannot be before start year"
            });
        }

        // CGPA range validation
        if (cgpa !== undefined && (cgpa < 0 || cgpa > 10)) {
            return res.status(400).json({
                message: "CGPA must be between 0 and 10"
            });
        }

        const education = await Education.create({
            userId: req.user.id,
            degree,
            institution,
            branch,
            startYear,
            endYear,
            cgpa,
            educationLevel
        });

        res.status(201).json({
            message: "Education record created successfully",
            data: education
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

// GET /api/education — Get all education records for logged-in user
const getEducations = async (req, res) => {
    try {
        const educations = await Education.find({ userId: req.user.id }).sort({ startYear: -1 });

        res.status(200).json({
            count: educations.length,
            data: educations
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

// GET /api/education/:id — Get a single education record by ID
const getEducationById = async (req, res) => {
    try {
        // Validate ObjectId format
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid education ID"
            });
        }

        const education = await Education.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!education) {
            return res.status(404).json({
                message: "Education record not found"
            });
        }

        res.status(200).json({
            data: education
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

// PUT /api/education/:id — Update an education record
const updateEducation = async (req, res) => {
    try {
        // Validate ObjectId format
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid education ID"
            });
        }

        const education = await Education.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!education) {
            return res.status(404).json({
                message: "Education record not found"
            });
        }

        const { degree, institution, branch, startYear, endYear, cgpa, educationLevel } = req.body;

        // Year validation
        const resolvedStart = startYear ?? education.startYear;
        const resolvedEnd = endYear ?? education.endYear;
        if (resolvedStart && resolvedEnd && resolvedEnd < resolvedStart) {
            return res.status(400).json({
                message: "End year cannot be before start year"
            });
        }

        // CGPA range validation
        const resolvedCgpa = cgpa ?? education.cgpa;
        if (resolvedCgpa !== undefined && resolvedCgpa !== null && (resolvedCgpa < 0 || resolvedCgpa > 10)) {
            return res.status(400).json({
                message: "CGPA must be between 0 and 10"
            });
        }

        // Build explicit update payload — userId is strictly excluded
        const updatePayload = {};
        if (degree !== undefined) updatePayload.degree = degree.trim ? degree.trim() : degree;
        if (institution !== undefined) updatePayload.institution = institution.trim ? institution.trim() : institution;
        if (branch !== undefined) updatePayload.branch = branch;
        if (startYear !== undefined) updatePayload.startYear = startYear;
        if (endYear !== undefined) updatePayload.endYear = endYear;
        if (cgpa !== undefined) updatePayload.cgpa = cgpa;
        if (educationLevel !== undefined) updatePayload.educationLevel = educationLevel;

        const updatedEducation = await Education.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            {
                new: true,
                runValidators: true
            }
        );

        res.status(200).json({
            message: "Education record updated successfully",
            data: updatedEducation
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

// DELETE /api/education/:id — Delete an education record
const deleteEducation = async (req, res) => {
    try {
        // Validate ObjectId format
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid education ID"
            });
        }

        const education = await Education.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!education) {
            return res.status(404).json({
                message: "Education record not found"
            });
        }

        await Education.findByIdAndDelete(req.params.id);

        res.status(200).json({
            message: "Education record deleted successfully"
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

module.exports = {
    createEducation,
    getEducations,
    getEducationById,
    updateEducation,
    deleteEducation
};
