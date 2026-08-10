/**
 * overdueTaskJob.js
 * Checks for overdue tasks every 4 hours and sends push notifications.
 * Uses a timestamp-based cooldown stored on each task to avoid spamming.
 * A task gets a reminder at most once every 4 hours.
 */

const Task = require('../models/Task');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

// Cooldown: 4 hours in milliseconds
const REMINDER_INTERVAL_MS = 4 * 60 * 60 * 1000;

// In-memory map: taskId -> last notified timestamp
// This is fine — if server restarts, worst case a single extra notification fires
const lastNotifiedAt = new Map();

async function runOverdueCheck() {
  try {
    const now = new Date();

    // Fetch admins once for all tasks (avoids N+1 queries)
    const [overdueTasks, reviewers] = await Promise.all([
      Task.find({
        dueDate: { $lt: now },
        status: { $in: ['pending', 'in-progress', 'rejected'] }
      }).select('_id title dueDate assignedTo').lean(),
      User.find({ role: 'admin' }).select('_id').lean()
    ]);

    if (overdueTasks.length === 0) return;
    console.log(`⏰ Overdue check: ${overdueTasks.length} overdue task(s)`);

    const reviewerIds = reviewers.map(r => r._id);

    for (const task of overdueTasks) {
      const taskId = task._id.toString();
      const lastSent = lastNotifiedAt.get(taskId) || 0;

      // Skip if we notified within the last 4 hours
      if (now.getTime() - lastSent < REMINDER_INTERVAL_MS) continue;

      // Update the cooldown timestamp before sending
      lastNotifiedAt.set(taskId, now.getTime());

      const hoursOverdue = Math.floor((now - task.dueDate) / (1000 * 60 * 60));
      const overdueText = hoursOverdue < 24
        ? `${hoursOverdue} hour${hoursOverdue !== 1 ? 's' : ''} overdue`
        : `${Math.floor(hoursOverdue / 24)} day${Math.floor(hoursOverdue / 24) !== 1 ? 's' : ''} overdue`;

      // Fire both in parallel to avoid awaiting sequentially per task
      const notifications = [];

      if (task.assignedTo.length > 0) {
        notifications.push(
          notificationService.sendToMultiple(task.assignedTo, {
            title: '⚠️ Task Overdue Reminder',
            body: `"${task.title}" is ${overdueText}. Please submit your work.`,
            data: { taskId, type: 'TASK_OVERDUE' }
          })
        );
      }

      if (reviewerIds.length > 0) {
        notifications.push(
          notificationService.sendToMultiple(reviewerIds, {
            title: '⚠️ Overdue Task Alert',
            body: `"${task.title}" is ${overdueText} — needs attention`,
            data: { taskId, type: 'TASK_OVERDUE_ADMIN' }
          })
        );
      }

      await Promise.all(notifications);
      console.log(`⏰ Reminder sent for overdue task: "${task.title}" (${overdueText})`);
    }
  } catch (error) {
    console.error('❌ Overdue task job error:', error.message);
  }
}

function startOverdueTaskJob() {
  console.log('⏰ Overdue task scheduler started (runs every 4 hours)');
  // Run once at startup, then every 4 hours
  runOverdueCheck();
  setInterval(runOverdueCheck, REMINDER_INTERVAL_MS);
}

module.exports = { startOverdueTaskJob };
