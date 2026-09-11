const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendOtpEmail } = require('../emailService');

// Create a new user (Register)
router.post('/create', async (req, res) => {
  try {
    const { name, email, password, phone, role } = req.body;

    const hashedPassword = await bcrypt.hash(password, 10);
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

    const newUser = new User({
      name,
      email,
      password: hashedPassword,
      phone,
      role,
      isVerified: false,
      otp,
      otpExpiry,
    });

        const savedUser = await newUser.save();

    res.status(201).json({ message: 'Registered. Check your email for the verification code.', userId: savedUser._id });

    sendOtpEmail(email, otp).catch((err) =>
      console.error('Failed to send OTP email:', err.message)
    );
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }
        if (!user.isVerified) {
      return res.status(403).json({ error: 'Please verify your email before logging in' });
    }

    // Compare entered password with hashed password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    const userResponse = {
  _id: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  role: user.role,
};

res.status(200).json({ token, user: userResponse });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.patch('/:userId/fcm-token', async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const updatedUser = await User.findByIdAndUpdate(
      req.params.userId,
      { fcmToken },
      { new: true }
    );
    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
router.post('/verify-otp', async (req, res) => {
  try {
    const { userId, otp } = req.body;
    const user = await User.findById(userId);

    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.isVerified) return res.status(400).json({ error: 'Already verified' });
    if (user.otp !== otp) return res.status(400).json({ error: 'Invalid OTP' });
    if (user.otpExpiry < new Date()) return res.status(400).json({ error: 'OTP expired' });

    user.isVerified = true;
    user.otp = undefined;
    user.otpExpiry = undefined;
    await user.save();

    res.status(200).json({ message: 'Email verified successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
module.exports = router;