const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/authRoutes");
const studentRoutes = require("./routes/studentRoutes");
const skillRoutes = require("./routes/skillRoutes");
const educationRoutes = require("./routes/educationRoutes");
const projectRoutes = require("./routes/projectRoutes");
const certificationRoutes = require("./routes/certificationRoutes");
const resumeRoutes = require("./routes/resumeRoutes");
const jobRoutes = require("./routes/jobRoutes");
const applicationRoutes = require("./routes/applicationRoutes");
const adminRoutes = require("./routes/adminRoutes");

const app = express();

app.use(cors());
app.use(express.json());

mongoose
    .connect(process.env.MONGO_URI)
    .then(() => {
        console.log("MongoDB Connected Successfully");
    })
    .catch((error) => {
        console.log("MongoDB Connection Failed:", error.message);
    });

app.get("/", (req, res) => {
    res.json({
        message: "Student Career System API is running"
    });
});

app.get("/health", (req, res) => {
    res.json({
        status: "OK"
    });
});

app.use("/api/auth", authRoutes);

app.use("/api/students", studentRoutes);

app.use("/api/skills", skillRoutes);

app.use("/api/education", educationRoutes);

app.use("/api/projects", projectRoutes);

app.use("/api/certifications", certificationRoutes);

app.use("/api/resume", resumeRoutes);

app.use("/api/jobs", jobRoutes);

app.use("/api/applications", applicationRoutes);

app.use("/api/admin", adminRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});