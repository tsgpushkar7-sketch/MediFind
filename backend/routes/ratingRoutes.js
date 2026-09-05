const express = require('express');
const router = express.Router();
const Rating = require('../models/Rating');

// Submit a rating
router.post('/create', async (req, res) => {
  try {
    const newRating = new Rating(req.body);
    const savedRating = await newRating.save();
    res.status(201).json(savedRating);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get all ratings for a specific shop
router.get('/shop/:shopId', async (req, res) => {
  try {
    const ratings = await Rating.find({ shopId: req.params.shopId });
    res.status(200).json(ratings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;