const express = require("express");
const router = express.Router();

const {
    createCertification,
    getCertifications,
    getCertificationById,
    updateCertification,
    deleteCertification
} = require("../controllers/certificationController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/", authMiddleware, createCertification);

router.get("/", authMiddleware, getCertifications);

router.get("/:id", authMiddleware, getCertificationById);

router.put("/:id", authMiddleware, updateCertification);

router.delete("/:id", authMiddleware, deleteCertification);

module.exports = router;
