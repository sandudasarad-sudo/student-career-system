const mongoose = require("mongoose");
const Certification = require("../models/Certification");

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Returns true if the string is a valid http/https URL.
 * Uses the built-in URL constructor — no extra packages needed.
 */
const isValidUrl = (value) => {
    try {
        const url = new URL(value);
        return url.protocol === "http:" || url.protocol === "https:";
    } catch {
        return false;
    }
};

// ─── POST /api/certifications ────────────────────────────────────────────────

const createCertification = async (req, res) => {
    try {
        const {
            title,
            issuer,
            issueDate,
            expiryDate,
            credentialId,
            credentialUrl,
            description
        } = req.body;

        // Required field validation
        if (!title || !title.trim()) {
            return res.status(400).json({ message: "Certification title is required" });
        }
        if (!issuer || !issuer.trim()) {
            return res.status(400).json({ message: "Issuer is required" });
        }
        if (!issueDate) {
            return res.status(400).json({ message: "Issue date is required" });
        }

        // issueDate must be a valid date
        if (isNaN(Date.parse(issueDate))) {
            return res.status(400).json({ message: "issueDate is not a valid date" });
        }

        // expiryDate validation
        if (expiryDate !== undefined && expiryDate !== null && expiryDate !== "") {
            if (isNaN(Date.parse(expiryDate))) {
                return res.status(400).json({ message: "expiryDate is not a valid date" });
            }
            if (new Date(expiryDate) < new Date(issueDate)) {
                return res.status(400).json({
                    message: "expiryDate cannot be earlier than issueDate"
                });
            }
        }

        // credentialUrl validation
        if (credentialUrl && !isValidUrl(credentialUrl)) {
            return res.status(400).json({
                message: "credentialUrl must be a valid URL (http/https)"
            });
        }

        const certification = await Certification.create({
            userId: req.user.id,
            title: title.trim(),
            issuer: issuer.trim(),
            issueDate,
            expiryDate: (expiryDate !== undefined && expiryDate !== null && expiryDate !== "")
                ? expiryDate
                : undefined,
            credentialId,
            credentialUrl,
            description
        });

        return res.status(201).json({
            message: "Certification created successfully",
            data: certification
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/certifications ─────────────────────────────────────────────────

const getCertifications = async (req, res) => {
    try {
        const certifications = await Certification
            .find({ userId: req.user.id })
            .sort({ issueDate: -1 });

        return res.status(200).json({
            count: certifications.length,
            data: certifications
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── GET /api/certifications/:id ─────────────────────────────────────────────

const getCertificationById = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid certification ID" });
        }

        const certification = await Certification.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!certification) {
            return res.status(404).json({ message: "Certification not found" });
        }

        return res.status(200).json({ data: certification });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── PUT /api/certifications/:id ─────────────────────────────────────────────

const updateCertification = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid certification ID" });
        }

        // Ownership check — if the user doesn't own it, treat as not found
        const certification = await Certification.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!certification) {
            return res.status(404).json({ message: "Certification not found" });
        }

        const {
            title,
            issuer,
            issueDate,
            expiryDate,
            credentialId,
            credentialUrl,
            description
        } = req.body;

        // Validate provided fields only (partial update)
        if (title !== undefined && !title.trim()) {
            return res.status(400).json({ message: "Certification title cannot be empty" });
        }
        if (issuer !== undefined && !issuer.trim()) {
            return res.status(400).json({ message: "Issuer cannot be empty" });
        }

        // issueDate — validate if provided
        if (issueDate !== undefined && isNaN(Date.parse(issueDate))) {
            return res.status(400).json({ message: "issueDate is not a valid date" });
        }

        // expiryDate — validate if provided and not null/empty
        if (expiryDate !== undefined && expiryDate !== null && expiryDate !== "") {
            if (isNaN(Date.parse(expiryDate))) {
                return res.status(400).json({ message: "expiryDate is not a valid date" });
            }
        }

        // expiryDate vs issueDate — resolve against existing values for partial updates
        const resolvedIssueDate  = issueDate  !== undefined ? new Date(issueDate)  : certification.issueDate;
        const resolvedExpiryDate = expiryDate !== undefined && expiryDate !== null && expiryDate !== ""
            ? new Date(expiryDate)
            : certification.expiryDate;

        if (resolvedIssueDate && resolvedExpiryDate && resolvedExpiryDate < resolvedIssueDate) {
            return res.status(400).json({
                message: "expiryDate cannot be earlier than issueDate"
            });
        }

        // credentialUrl validation
        if (credentialUrl !== undefined && credentialUrl !== "" && !isValidUrl(credentialUrl)) {
            return res.status(400).json({
                message: "credentialUrl must be a valid URL (http/https)"
            });
        }

        // Build update payload — userId is intentionally excluded to prevent ownership hijack
        const updatePayload = {};
        if (title         !== undefined) updatePayload.title         = title.trim();
        if (issuer        !== undefined) updatePayload.issuer        = issuer.trim();
        if (issueDate     !== undefined) updatePayload.issueDate     = issueDate;
        if (expiryDate    !== undefined) updatePayload.expiryDate    = (expiryDate === null || expiryDate === "") ? null : expiryDate;
        if (credentialId  !== undefined) updatePayload.credentialId  = credentialId;
        if (credentialUrl !== undefined) updatePayload.credentialUrl = credentialUrl;
        if (description   !== undefined) updatePayload.description   = description;
        // userId is never in updatePayload

        const updatedCertification = await Certification.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            { new: true, runValidators: true }
        );

        return res.status(200).json({
            message: "Certification updated successfully",
            data: updatedCertification
        });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── DELETE /api/certifications/:id ──────────────────────────────────────────

const deleteCertification = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: "Invalid certification ID" });
        }

        const certification = await Certification.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!certification) {
            return res.status(404).json({ message: "Certification not found" });
        }

        await Certification.findByIdAndDelete(req.params.id);

        return res.status(200).json({ message: "Certification deleted successfully" });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
};

// ─── Exports ─────────────────────────────────────────────────────────────────

module.exports = {
    createCertification,
    getCertifications,
    getCertificationById,
    updateCertification,
    deleteCertification
};
