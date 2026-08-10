const Task = require('../models/Task');
const User = require('../models/User');
const Submission = require('../models/Submission');
const logger = require('../utils/logger');
const mongoose = require('mongoose');
const { buildOrganizationFilter, buildAggregationMatch } = require('../utils/multiTenantHelpers');

/**
 * @desc    Get overall system stats
 * @route   GET /api/v1/analytics/stats
 * @access  Private/Admin
 */
exports.getSystemStats = async (req, res) => {
    try {
        const filter = buildOrganizationFilter(req, {});

        const totalTasks = await Task.countDocuments(filter);
        const completedTasks = await Task.countDocuments({ ...filter, status: 'completed' });
        const pendingSubmissions = await Submission.countDocuments({ ...filter, status: 'pending' });
        
        // Count members (not super_admin) in organization
        const userFilter = buildOrganizationFilter(req, { role: 'member' });
        const totalUsers = await User.countDocuments(userFilter);

        res.status(200).json({
            success: true,
            data: {
                totalTasks,
                completedTasks,
                pendingSubmissions,
                totalMembers: totalUsers, // Updated from totalWorkers
                completionRate: totalTasks > 0 ? (completedTasks / totalTasks * 100).toFixed(2) : 0
            },
            message: "System statistics retrieved successfully"
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * @desc    Get leaderboard of top members by completed tasks
 * @route   GET /api/v1/analytics/leaderboard
 * @access  Private
 */
exports.getLeaderboard = async (req, res) => {
    try {
        const matchFilter = buildAggregationMatch(req, { status: 'completed' });

        // $unwind the assignedTo array so each user is counted individually
        const leaderboard = await Task.aggregate([
            { $match: matchFilter },
            { $unwind: '$assignedTo' },   // handles multi-user tasks
            {
                $group: {
                    _id: '$assignedTo',
                    tasksCompleted: { $sum: 1 }
                }
            },
            { $sort: { tasksCompleted: -1 } },
            { $limit: 10 },
            {
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'user'
                }
            },
            { $unwind: '$user' },
            {
                $project: {
                    _id: 1,
                    tasksCompleted: 1,
                    name: '$user.name',
                    username: '$user.username'
                }
            }
        ]);

        res.status(200).json({
            success: true,
            data: leaderboard,
            message: "Leaderboard retrieved successfully"
        });
    } catch (error) {
        logger.error('Get leaderboard error', { error: error.message });
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};


/**
 * @desc    Get team activity (who has assigned tasks)
 * @route   GET /api/v1/analytics/activity
 * @access  Private
 */
exports.getTeamActivity = async (req, res) => {
    try {
        const filter = buildOrganizationFilter(req, { status: { $ne: 'completed' } });

        const activeTasks = await Task.find(filter)
            .populate('assignedTo', 'name username')
            .select('title status assignedTo priority');

        // Grouping by user — assignedTo is now an ARRAY (multi-user tasks)
        const activityMap = {};
        activeTasks.forEach(task => {
            const assignees = Array.isArray(task.assignedTo) ? task.assignedTo : [task.assignedTo];
            assignees.forEach(user => {
                if (!user || !user._id) return;
                const userId = user._id.toString();
                if (!activityMap[userId]) {
                    activityMap[userId] = {
                        name: user.name,
                        username: user.username,
                        tasks: []
                    };
                }
                activityMap[userId].tasks.push({
                    id: task._id,
                    title: task.title,
                    status: task.status,
                    priority: task.priority
                });
            });
        });

        const activityList = Object.values(activityMap);

        res.status(200).json({
            success: true,
            data: activityList,
            message: "Team activity retrieved successfully"
        });
    } catch (error) {
        logger.error('Get team activity error', { error: error.message });
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

