/**
 * roleMiddleware.js
 *
 * Reusable role-based authorization middleware.
 * Must be used AFTER authMiddleware (which populates req.user).
 *
 * Usage:
 *   router.post("/", protect, requireRole("admin"), createJob);
 *   router.get("/", protect, requireRole("admin", "student"), getJobs);
 */

const requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !req.user.role) {
            return res.status(401).json({
                message: "Not authorized. Please login."
            });
        }

        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                message: "Access denied. You do not have permission to perform this action."
            });
        }

        next();
    };
};

module.exports = requireRole;
