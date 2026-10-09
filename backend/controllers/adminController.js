const mongoose = require("mongoose");
const User          = require("../models/User");
const Student       = require("../models/Student");
const Job           = require("../models/Job");
const Application   = require("../models/Application");
const Skill         = require("../models/Skill");
const Education     = require("../models/Education");
const Project       = require("../models/Project");
const Certification = require("../models/Certification");
const Resume        = require("../models/Resume");

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Escapes characters with special meaning in RegExp to prevent regex injection.
 */
const escapeRegex = (string) => {
    return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
};

// ─── GET /api/admin/dashboard ─────────────────────────────────────────────────

const getDashboard = async (req, res) => {
    try {
        const now = new Date();

        const [
            userRoleAgg,
            totalStudentsWithProfile,
            studentCgpaAgg,
            totalResumes,
            totalSkills,
            totalEducation,
            totalProjects,
            totalCertifications,
            totalJobs,
            activeJobs,
            inactiveJobs,
            expiredJobs,
            totalApplications,
            appStatusAgg,
            recentApplications,
            recentStudents
        ] = await Promise.all([
            // 1. User stats by role
            User.aggregate([
                { $group: { _id: "$role", count: { $sum: 1 } } }
            ]),
            // 2. Student profiles count
            Student.countDocuments(),
            // 3. Student CGPA stats
            Student.aggregate([
                { $match: { cgpa: { $ne: null, $exists: true } } },
                { $group: { _id: null, count: { $sum: 1 }, avgCgpa: { $avg: "$cgpa" } } }
            ]),
            // 4. Resumes count
            Resume.countDocuments(),
            // 5. Skills count
            Skill.countDocuments(),
            // 6. Education count
            Education.countDocuments(),
            // 7. Projects count
            Project.countDocuments(),
            // 8. Certifications count
            Certification.countDocuments(),
            // 9. Total jobs
            Job.countDocuments(),
            // 10. Active jobs
            Job.countDocuments({ isActive: true }),
            // 11. Inactive jobs
            Job.countDocuments({ isActive: false }),
            // 12. Expired jobs
            Job.countDocuments({ applicationDeadline: { $lt: now } }),
            // 13. Total applications
            Application.countDocuments(),
            // 14. Applications by status
            Application.aggregate([
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]),
            // 15. Recent 10 applications with safe populated fields
            Application.find()
                .sort({ appliedAt: -1 })
                .limit(10)
                .populate("userId", "name email")
                .populate("jobId", "title company location jobType")
                .select("-adminNotes -__v"),
            // 16. Recent 10 registered students without sensitive fields
            User.find({ role: "student" })
                .sort({ createdAt: -1 })
                .limit(10)
                .select("-password -__v")
        ]);

        // Process user counts
        let studentUsersCount = 0;
        let adminUsersCount = 0;
        let totalUsersCount = 0;

        userRoleAgg.forEach((item) => {
            totalUsersCount += item.count;
            if (item._id === "student") studentUsersCount = item.count;
            if (item._id === "admin") adminUsersCount = item.count;
        });

        // Process application statuses with guaranteed 0 for empty statuses
        const applicationStatusCounts = {
            "Applied": 0,
            "Under Review": 0,
            "Shortlisted": 0,
            "Rejected": 0,
            "Selected": 0,
            "Withdrawn": 0
        };

        appStatusAgg.forEach((item) => {
            if (item._id && applicationStatusCounts.hasOwnProperty(item._id)) {
                applicationStatusCounts[item._id] = item.count;
            }
        });

        // Process CGPA stats
        const studentsWithCgpa = studentCgpaAgg[0] ? studentCgpaAgg[0].count : 0;
        const rawAvg = studentCgpaAgg[0] && studentCgpaAgg[0].avgCgpa != null
            ? studentCgpaAgg[0].avgCgpa
            : 0;
        const averageCgpa = parseFloat(rawAvg.toFixed(2));

        return res.status(200).json({
            message: "Dashboard data retrieved successfully",
            data: {
                users: {
                    total: totalUsersCount,
                    students: studentUsersCount,
                    admins: adminUsersCount
                },
                profiles: {
                    studentsWithProfile: totalStudentsWithProfile,
                    resumes: totalResumes,
                    studentsWithCgpa,
                    averageCgpa
                },
                careerData: {
                    skills: totalSkills,
                    educationRecords: totalEducation,
                    projects: totalProjects,
                    certifications: totalCertifications
                },
                jobs: {
                    total: totalJobs,
                    active: activeJobs,
                    inactive: inactiveJobs,
                    expired: expiredJobs
                },
                applications: {
                    total: totalApplications,
                    ...applicationStatusCounts
                },
                recentApplications,
                recentStudents
            }
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/admin/users ─────────────────────────────────────────────────────

const getUsers = async (req, res) => {
    try {
        const { page = 1, limit = 10, search, role } = req.query;

        const pageNum = Math.max(1, parseInt(page, 10) || 1);
        const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 10));
        const skip = (pageNum - 1) * limitNum;

        const query = {};

        if (role) {
            query.role = role;
        }

        if (search && search.trim()) {
            const escaped = escapeRegex(search.trim());
            query.$or = [
                { name: { $regex: escaped, $options: "i" } },
                { email: { $regex: escaped, $options: "i" } }
            ];
        }

        const [totalUsers, users] = await Promise.all([
            User.countDocuments(query),
            User.find(query)
                .select("-password -__v")
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limitNum)
        ]);

        return res.status(200).json({
            count: users.length,
            total: totalUsers,
            page: pageNum,
            limit: limitNum,
            totalPages: Math.ceil(totalUsers / limitNum) || 0,
            data: users
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/admin/users/:id ─────────────────────────────────────────────────

const getUserById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid user ID" });
        }

        const user = await User.findById(req.params.id).select("-password -__v");

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Attach corresponding student profile if one exists
        const studentProfile = await Student.findOne({ userId: user._id }).select("-__v");

        return res.status(200).json({
            data: {
                user,
                studentProfile: studentProfile || null
            }
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/admin/students ──────────────────────────────────────────────────

const getStudents = async (req, res) => {
    try {
        const { page = 1, limit = 10, search, branch, year } = req.query;

        const pageNum = Math.max(1, parseInt(page, 10) || 1);
        const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 10));
        const skip = (pageNum - 1) * limitNum;

        const query = {};

        if (branch && branch.trim()) {
            query.branch = { $regex: `^${escapeRegex(branch.trim())}$`, $options: "i" };
        }

        if (year) {
            const parsedYear = parseInt(year, 10);
            if (!isNaN(parsedYear)) {
                query.year = parsedYear;
            }
        }

        if (search && search.trim()) {
            const escaped = escapeRegex(search.trim());
            query.$or = [
                { name: { $regex: escaped, $options: "i" } },
                { email: { $regex: escaped, $options: "i" } },
                { college: { $regex: escaped, $options: "i" } }
            ];
        }

        const [totalStudents, students] = await Promise.all([
            Student.countDocuments(query),
            Student.find(query)
                .populate("userId", "name email role createdAt")
                .select("-__v")
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limitNum)
        ]);

        return res.status(200).json({
            count: students.length,
            total: totalStudents,
            page: pageNum,
            limit: limitNum,
            totalPages: Math.ceil(totalStudents / limitNum) || 0,
            data: students
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/admin/students/:userId ──────────────────────────────────────────

const getStudentDetails = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.userId)) {
            return res.status(400).json({ message: "Invalid user ID" });
        }

        const user = await User.findById(req.params.userId).select("-password -__v");

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Consolidated lookup across student data collections
        const [
            student,
            skills,
            education,
            projects,
            certifications,
            resume,
            applications
        ] = await Promise.all([
            Student.findOne({ userId: req.params.userId }).select("-__v"),
            Skill.find({ userId: req.params.userId }).select("-__v"),
            Education.find({ userId: req.params.userId }).sort({ startYear: -1 }).select("-__v"),
            Project.find({ userId: req.params.userId }).sort({ createdAt: -1 }).select("-__v"),
            Certification.find({ userId: req.params.userId }).sort({ issueDate: -1 }).select("-__v"),
            Resume.findOne({ userId: req.params.userId })
                .populate("educationIds", "-userId -__v")
                .populate("skillIds", "-userId -__v")
                .populate("projectIds", "-userId -__v")
                .populate("certificationIds", "-userId -__v")
                .select("-__v"),
            Application.find({ userId: req.params.userId })
                .populate("jobId", "title company location jobType")
                .sort({ appliedAt: -1 })
                .select("-__v")
        ]);

        return res.status(200).json({
            message: "Student details retrieved successfully",
            data: {
                user,
                student: student || null,
                skills,
                education,
                projects,
                certifications,
                resume: resume || null,
                applications
            }
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/admin/analytics/applications ────────────────────────────────────

const getApplicationAnalytics = async (req, res) => {
    try {
        const [totalApplications, statusAgg, appsByJobAgg] = await Promise.all([
            Application.countDocuments(),
            Application.aggregate([
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]),
            Application.aggregate([
                { $group: { _id: "$jobId", applicationCount: { $sum: 1 } } },
                { $sort: { applicationCount: -1 } },
                { $limit: 10 },
                {
                    $lookup: {
                        from: "jobs",
                        localField: "_id",
                        foreignField: "_id",
                        as: "job"
                    }
                },
                { $unwind: "$job" },
                {
                    $project: {
                        _id: 0,
                        jobId: "$job._id",
                        jobTitle: "$job.title",
                        company: "$job.company",
                        applicationCount: 1
                    }
                }
            ])
        ]);

        const statusCounts = {
            "Applied": 0,
            "Under Review": 0,
            "Shortlisted": 0,
            "Rejected": 0,
            "Selected": 0,
            "Withdrawn": 0
        };

        statusAgg.forEach((item) => {
            if (item._id && statusCounts.hasOwnProperty(item._id)) {
                statusCounts[item._id] = item.count;
            }
        });

        return res.status(200).json({
            message: "Application analytics retrieved successfully",
            data: {
                total: totalApplications,
                statusCounts,
                applicationsByJob: appsByJobAgg
            }
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/admin/analytics/jobs ────────────────────────────────────────────

const getJobAnalytics = async (req, res) => {
    try {
        const now = new Date();

        const [
            totalJobs,
            activeJobs,
            inactiveJobs,
            expiredJobs,
            topJobsAgg
        ] = await Promise.all([
            Job.countDocuments(),
            Job.countDocuments({ isActive: true }),
            Job.countDocuments({ isActive: false }),
            Job.countDocuments({ applicationDeadline: { $lt: now } }),
            Application.aggregate([
                { $group: { _id: "$jobId", applicationCount: { $sum: 1 } } },
                { $sort: { applicationCount: -1 } },
                { $limit: 5 },
                {
                    $lookup: {
                        from: "jobs",
                        localField: "_id",
                        foreignField: "_id",
                        as: "job"
                    }
                },
                { $unwind: "$job" },
                {
                    $project: {
                        _id: 0,
                        jobId: "$job._id",
                        title: "$job.title",
                        company: "$job.company",
                        jobType: "$job.jobType",
                        isActive: "$job.isActive",
                        applicationDeadline: "$job.applicationDeadline",
                        applicationCount: 1
                    }
                }
            ])
        ]);

        return res.status(200).json({
            message: "Job analytics retrieved successfully",
            data: {
                summary: {
                    total: totalJobs,
                    active: activeJobs,
                    inactive: inactiveJobs,
                    expired: expiredJobs
                },
                topJobs: topJobsAgg
            }
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── Exports ──────────────────────────────────────────────────────────────────

module.exports = {
    getDashboard,
    getUsers,
    getUserById,
    getStudents,
    getStudentDetails,
    getApplicationAnalytics,
    getJobAnalytics
};
