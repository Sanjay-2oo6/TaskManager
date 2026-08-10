/**
 * Create Test Users for Mobile Testing
 * 
 * This script bypasses the pre-save middleware to properly create users
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('../models/User');
const Organization = require('../models/Organization');

const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/taskmanager';

async function createTestUsers() {
  try {
    console.log('\n🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    // Delete existing test users
    await User.deleteMany({ email: { $in: ['superadmin@ithub.com', 'admin@ith.com', 'member@ith.com'] } });
    await Organization.deleteMany({ slug: 'ith' });
    console.log('🗑️  Cleaned up existing test data\n');

    // ═══════════════════════════════════════════════════════════════════════
    // 1. CREATE SUPER ADMIN FIRST (needed for organization creation)
    // ═══════════════════════════════════════════════════════════════════════
    console.log('👑 Creating Super Admin account...');
    const superAdminPassword = 'SuperAdmin123!';
    const superAdminHashedPassword = await bcrypt.hash(superAdminPassword, 10);

    const superAdmin = new User({
      name: 'Super Admin',
      username: 'superadmin',
      email: 'superadmin@ithub.com',
      password: superAdminHashedPassword,
      role: 'super_admin',
      organizationId: null,
      isActive: true
    });

    await superAdmin.validate();
    const savedSuperAdmin = await User.collection.insertOne(superAdmin.toObject());
    const superAdminId = superAdmin._id;

    console.log(`✅ Super Admin created:`);
    console.log(`   📧 Email: superadmin@ithub.com`);
    console.log(`   🔑 Password: ${superAdminPassword}\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // 2. CREATE ITH ORGANIZATION
    // ═══════════════════════════════════════════════════════════════════════
    console.log('🏢 Creating ITH organization...');
    const ithOrg = await Organization.create({
      name: 'INNO TECH HUB',
      slug: 'ith',
      adminId: superAdminId, // Temporarily set super admin
      createdBy: superAdminId, // Creator is super admin
      memberLimit: -1,
      isActive: true,
      isSpecial: true,
      welcomeMessage: 'Welcome to INNO TECH HUB - Where Innovation Meets Excellence!',
      themeColor: '#FF6B6B',
      subscriptionTier: 'custom',
    });
    console.log(`✅ ITH organization created\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // 3. CREATE ITH ADMIN
    // ═══════════════════════════════════════════════════════════════════════
    console.log('👨‍💼 Creating ITH Admin account...');
    const adminPassword = 'ITHAdmin123!';
    const adminHashedPassword = await bcrypt.hash(adminPassword, 10);

    const ithAdmin = new User({
      name: 'ITH Admin',
      username: 'ithadmin',
      email: 'admin@ith.com',
      password: adminHashedPassword, // Pre-hashed password
      role: 'admin',
      organizationId: ithOrg._id,
      isActive: true
    });

    await ithAdmin.validate();
    await User.collection.insertOne(ithAdmin.toObject());

    console.log(`✅ ITH Admin created:`);
    console.log(`   📧 Email: admin@ith.com`);
    console.log(`   🔑 Password: ${adminPassword}\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // 4. CREATE TEST MEMBER
    // ═══════════════════════════════════════════════════════════════════════
    console.log('👤 Creating Test Member account...');
    const memberPassword = 'Member123!';
    const memberHashedPassword = await bcrypt.hash(memberPassword, 10);

    const testMember = new User({
      name: 'Test Member',
      username: 'testmember',
      email: 'member@ith.com',
      password: memberHashedPassword, // Pre-hashed password
      role: 'member',
      organizationId: ithOrg._id,
      isActive: true
    });

    await testMember.validate();
    await User.collection.insertOne(testMember.toObject());

    console.log(`✅ Test Member created:`);
    console.log(`   📧 Email: member@ith.com`);
    console.log(`   🔑 Password: ${memberPassword}\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // 5. UPDATE ORGANIZATION WITH ADMIN
    // ═══════════════════════════════════════════════════════════════════════
    await Organization.findByIdAndUpdate(ithOrg._id, { adminId: ithAdmin._id });

    // ═══════════════════════════════════════════════════════════════════════
    // SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    console.log('═'.repeat(70));
    console.log('✅ TEST USERS CREATED SUCCESSFULLY');
    console.log('═'.repeat(70));
    
    console.log('\n👑 Super Admin (for managing organizations):');
    console.log(`   📧 Email: superadmin@ithub.com`);
    console.log(`   🔑 Password: ${superAdminPassword}`);
    
    console.log('\n👨‍💼 ITH Admin (for managing team & creating tasks):');
    console.log(`   📧 Email: admin@ith.com`);
    console.log(`   🔑 Password: ${adminPassword}`);
    
    console.log('\n👤 Test Member (for submitting work):');
    console.log(`   📧 Email: member@ith.com`);
    console.log(`   🔑 Password: ${memberPassword}`);
    
    console.log('\n💡 Test in this order:');
    console.log(`   1. Log in as admin@ith.com to create tasks`);
    console.log(`   2. Log in as member@ith.com to view & submit tasks`);
    console.log(`   3. Switch back to admin to review submissions`);
    
    console.log('\n' + '═'.repeat(70) + '\n');

  } catch (error) {
    console.error('❌ Error creating test users:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

createTestUsers();
