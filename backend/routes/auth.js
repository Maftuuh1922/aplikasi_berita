const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const multer = require('multer');

const User = require('../models/user');
const Comment = require('../models/comment');
const { verifyToken } = require('../middleware/auth');

/* ── Google OAuth2 client ── */
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/* ── Multer setup ── */
const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, 'uploads/'),
  filename: (_, file, cb) => cb(null, Date.now() + '-' + file.originalname)
});
const upload = multer({ storage });

/* ── Register dengan Email ── */
router.post('/auth/register', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validasi input
    if (!email || !password) {
      return res.status(400).json({ message: 'Email dan password wajib diisi' });
    }

    // Cek apakah email sudah terdaftar
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email sudah terdaftar' });
    }

    // Buat user baru
    const user = await User.create({
      email,
      password,
      displayName: email.split('@')[0], // Gunakan bagian depan email sebagai displayName
    });

    // Generate JWT token
    const token = jwt.sign(
      { id: user._id, email: user.email, name: user.displayName },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Kirim response
    res.status(201).json({
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.displayName
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Terjadi kesalahan saat registrasi' });
  }
});

/* ── Login Google ── */
// ... kode lainnya ...

module.exports = router; 