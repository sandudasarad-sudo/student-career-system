const mongoose = require("mongoose");
const Student = require("../models/Student");

const createStudent = async (req, res) => {
    try {
        const {
            name,
            email,
            phone,
            dateOfBirth,
            gender,
            college,
            branch,
            year,
            cgpa,
            skills,
            address
        } = req.body;

        if (!name || !email) {
            return res.status(400).json({
                message: "Name and email are required"
            });
        }

        const existingStudent = await Student.findOne({
            userId: req.user.id
        });

        if (existingStudent) {
            return res.status(400).json({
                message: "Student profile already exists"
            });
        }

        const student = await Student.create({
            userId: req.user.id,
            name,
            email,
            phone,
            dateOfBirth,
            gender,
            college,
            branch,
            year,
            cgpa,
            skills,
            address
        });

        res.status(201).json({
            message: "Student profile created successfully",
            student
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const getStudents = async (req, res) => {
    try {
        const students = await Student.find().populate(
            "userId",
            "name email role"
        );

        res.status(200).json({
            count: students.length,
            students
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const getStudentById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid student ID"
            });
        }

        const student = await Student.findById(req.params.id).populate(
            "userId",
            "name email role"
        );

        if (!student) {
            return res.status(404).json({
                message: "Student not found"
            });
        }

        res.status(200).json({
            student
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const updateStudent = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid student ID"
            });
        }

        const student = await Student.findById(req.params.id);

        if (!student) {
            return res.status(404).json({
                message: "Student not found"
            });
        }

        if (student.userId.toString() !== req.user.id) {
            return res.status(403).json({
                message: "You are not allowed to update this profile"
            });
        }

        const {
            name,
            email,
            phone,
            dateOfBirth,
            gender,
            college,
            branch,
            year,
            cgpa,
            skills,
            address
        } = req.body;

        // Build explicit update payload — userId is strictly excluded
        const updatePayload = {};
        if (name !== undefined) updatePayload.name = name;
        if (email !== undefined) updatePayload.email = email;
        if (phone !== undefined) updatePayload.phone = phone;
        if (dateOfBirth !== undefined) updatePayload.dateOfBirth = dateOfBirth;
        if (gender !== undefined) updatePayload.gender = gender;
        if (college !== undefined) updatePayload.college = college;
        if (branch !== undefined) updatePayload.branch = branch;
        if (year !== undefined) updatePayload.year = year;
        if (cgpa !== undefined) updatePayload.cgpa = cgpa;
        if (skills !== undefined) updatePayload.skills = skills;
        if (address !== undefined) updatePayload.address = address;

        const updatedStudent = await Student.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            {
                new: true,
                runValidators: true
            }
        );

        res.status(200).json({
            message: "Student profile updated successfully",
            student: updatedStudent
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

const deleteStudent = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({
                message: "Invalid student ID"
            });
        }

        const student = await Student.findById(req.params.id);

        if (!student) {
            return res.status(404).json({
                message: "Student not found"
            });
        }

        if (student.userId.toString() !== req.user.id) {
            return res.status(403).json({
                message: "You are not allowed to delete this profile"
            });
        }

        await Student.findByIdAndDelete(req.params.id);

        res.status(200).json({
            message: "Student profile deleted successfully"
        });
    } catch (error) {
        res.status(500).json({
            message: "Server error",
            error: error.message
        });
    }
};

module.exports = {
    createStudent,
    getStudents,
    getStudentById,
    updateStudent,
    deleteStudent
};