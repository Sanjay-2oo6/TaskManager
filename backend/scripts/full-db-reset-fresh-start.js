/**
 * Full Database Reset & Fresh Start
 * 
 * This script:
 * 1. Deletes ALL data (organizations, users, tasks, messages, submissions)
 * 2. Creates a new Super Admin account
 * 3. Recreates ITH organization
 * 4. Creates a new Admin account for ITH
 * 5. Cleans up member accounts
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const Organization = require('../models/Organization');
const User = require('../models/User');
const Task = require('../models/Task');
const Message = require('../models/Message');
const Submission = require('../models/Submission');

const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/taskmanager';

async function fullResetAndFreshStart() {
  try {
    // ═══════════════════════════════════════════════════════════════════════
    // 1. CONNECT TO DATABASE
    // ═══════════════════════════════════════════════════════════════════════
    console.log('\n🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected to MongoDB');

    // ═══════════════════════════════════════════════════════════════════════
    // 2. DELETE ALL DATA
    // ═══════════════════════════════════════════════════════════════════════
    console.log('\n🗑️  Deleting all data...');
    
    const deleteStats = await Promise.all([
      Organization.deleteMany({}),
      User.deleteMany({}),
      Task.deleteMany({}),
      Message.deleteMany({}),
      Submission.deleteMany({})
    ]);

    console.log(`   📊 Organizations deleted: ${deleteStats[0].deletedCount}`);
    console.log(`   👥 Users deleted: ${deleteStats[1].deletedCount}`);
    console.log(`   📋 Tasks deleted: ${deleteStats[2].deletedCount}`);
    console.log(`   💬 Messages deleted: ${deleteStats[3].deletedCount}`);
    console.log(`   📝 Submissions deleted: ${deleteStats[4].deletedCount}`);

    // ═══════════════════════════════════════════════════════════════════════
    // 3. CREATE NEW SUPER ADMIN ACCOUNT
    // ═══════════════════════════════════════════════════════════════════════
    console.log('\n👑 Creating new Super Admin account...');
    
    const superAdminPassword = 'SuperAdmin123!';
    const hashedPassword = await bcrypt.hash(superAdminPassword, 10);

    const superAdmin = await User.create({
      name: 'Super Admin',
      username: 'superadmin',
      email: 'superadmin@ithub.com',
      password: hashedPassword,
      role: 'super_admin',
      organizationId: null, // Super admin is not tied to any org
      isActive: true
    });

    console.log(`✅ Super Admin created:`);
    console.log(`   📧 Email: superadmin@ithub.com`);
    console.log(`   🔑 Password: ${superAdminPassword}`);
    console.log(`   🆔 User ID: ${superAdmin._id}`);

    // ═══════════════════════════════════════════════════════════════════════
    // 4. RECREATE ITH ORGANIZATION
    // ═══════════════════════════════════════════════════════════════════════
    console.log('\n🏢 Creating ITH organization...');
    
    // Note: We'll create ITH without admin first, then update it
    // Create a temporary admin for ITH (will be replaced after)
    const ithOrg = await Organization.create({
      name: 'INNO TECH HUB',
      slug: 'ith',
      adminId: superAdmin._id, // Temporarily set super admin as admin
      memberLimit: -1, // Unlimited
      isActive: true,
      isSpecial: true,
      welcomeMessage: 'Welcome to INNO TECH HUB - Where Innovation Meets Excellence!',
      themeColor: '#FF6B6B',
      createdBy: superAdmin._id,
      subscriptionTier: 'custom',
    });

    console.log(`✅ ITH organization created:`);
    console.log(`   🆔 Organization ID: ${ithOrg._id}`);
    console.log(`   📛 Name: ${ithOrg.name}`);
    console.log(`   🔗 Slug: ${ithOrg.slug}`);

    // ═══════════════════════════════════════════════════════════════════════
    // 5. CREATE NEW ADMIN ACCOUNT FOR ITH
    // ═══════════════════════════════════════════════════════════════════════
    console.log('\n👨‍💼 Creating new Admin account for ITH...');
    
    const adminPassword = 'ITHAdmin123!';
    const hashedAdminPassword = await bcrypt.hash(adminPassword, 10);

    const ithAdmin = await User.create({
      name: 'ITH Admin',
      username: 'ithadmin',
      email: 'admin@ith.com',
      password: hashedAdminPassword,
      role: 'admin',
      organizationId: ithOrg._id,
      isActive: true
    });

    // ═════════════════════════════════════════════════════════════════════
    // 6. UPDATE ITH ORGANIZATION TO USE NEW ADMIN
    // ═════════════════════════════════════════════════════════════════════
    console.log('\n🔄 Updating ITH organization with new admin...');
    await Organization.findByIdAndUpdate(ithOrg._id, { adminId: ithAdmin._id });

    console.log(`✅ ITH Admin created and assigned:`);
    console.log(`   📧 Email: admin@ith.com`);
    console.log(`   🔑 Password: ${adminPassword}`);
    console.log(`   🆔 User ID: ${ithAdmin._id}`);
    console.log(`   🏢 Organization: ITH`);

    // ═══════════════════════════════════════════════════════════════════════
    // 7. SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    console.log('\n' + '═'.repeat(70));
    console.log('✅ FRESH START COMPLETE');
    console.log('═'.repeat(70));
    console.log('\n📋 Database Status:');
    console.log(`   - All organizations deleted (except ITH)`);
    console.log(`   - All users deleted (except Super Admin & ITH Admin)`);
    console.log(`   - All tasks, messages, submissions deleted`);
    
    console.log('\n👑 Super Admin Account (for managing organizations):');
    console.log(`   📧 Email: superadmin@ithub.com`);
    console.log(`   🔑 Password: ${superAdminPassword}`);
    
    console.log('\n👨‍💼 ITH Organization Admin Account (for managing team):');
    console.log(`   📧 Email: admin@ith.com`);
    console.log(`   🔑 Password: ${adminPassword}`);
    
    console.log('\n💡 Next Steps:');
    console.log(`   1. Log in as Super Admin to create/activate new organizations`);
    console.log(`   2. Log in as ITH Admin to create team members and tasks`);
    console.log(`   3. Use member accounts to test task workflows`);
    
    console.log('\n' + '═'.repeat(70) + '\n');

  } catch (error) {
    console.error('❌ Error during database reset:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

// Run the reset
fullResetAndFreshStart();
